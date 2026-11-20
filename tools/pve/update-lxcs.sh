#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info() {
  clear 2>/dev/null || printf '\033[H\033[2J\033[3J'
  cat <<"EOF"
   __  __          __      __          __   _  ________
  / / / /___  ____/ /___ _/ /____     / /  | |/ / ____/
 / / / / __ \/ __  / __ `/ __/ _ \   / /   |   / /
/ /_/ / /_/ / /_/ / /_/ / /_/  __/  / /___/   / /___
\____/ .___/\__,_/\__,_/\__/\___/  /_____/_/|_\____/
    /_/

EOF
}
set -eEuo pipefail
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
CM='\xE2\x9C\x94\033'
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")

# Telemetry
source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/api/api.func") 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "update-lxcs" "pve"

header_info
echo "Loading..."
whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE LXC Updater" --yesno "This Will Update LXC Containers. Proceed?" 10 58
if whiptail --backtitle "Proxmox VE Helper Scripts" --title "Skip Not-Running Containers" --yesno "Do you want to skip containers that are not currently running?" 10 58; then
  SKIP_STOPPED="yes"
else
  SKIP_STOPPED="no"
fi

NODE=$(hostname)
EXCLUDE_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  EXCLUDE_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')
excluded_containers=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --checklist "\nSelect containers to skip from updates:\n" 16 $((MSG_MAX_LENGTH + 23)) 6 "${EXCLUDE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')

# The failing containers' output, for the user and for the telemetry trace.
RUN_LOG="/tmp/update-lxcs-$(date +%Y%m%d_%H%M%S).log"
SILENT_LOGFILE="$RUN_LOG"
UPDATE_OUTPUT=$(mktemp)

function needs_reboot() {
  local container=$1
  local os=$(pct config "$container" | awk '/^ostype/ {print $2}')
  local reboot_required_file="/var/run/reboot-required.pkgs"
  if [ -f "$reboot_required_file" ]; then
    if [[ "$os" == "ubuntu" || "$os" == "debian" ]]; then
      if pct exec "$container" -- [ -s "$reboot_required_file" ]; then
        return 0
      fi
    fi
  fi
  return 1
}

function update_container() {
  container=$1
  header_info
  name=$(pct exec "$container" hostname)
  os=$(pct config "$container" | awk '/^ostype/ {print $2}')
  if [[ "$os" == "ubuntu" || "$os" == "debian" || "$os" == "fedora" ]]; then
    disk_info=$(pct exec "$container" df /boot | awk 'NR==2{gsub("%","",$5); printf "%s %.1fG %.1fG %.1fG", $5, $3/1024/1024, $2/1024/1024, $4/1024/1024 }')
    read -ra disk_info_array <<<"$disk_info"
    echo -e "${BL}[Info]${GN} Updating ${BL}$container${CL} : ${GN}$name${CL} - ${YW}Boot Disk: ${disk_info_array[0]}% full [${disk_info_array[1]}/${disk_info_array[2]} used, ${disk_info_array[3]} free]${CL}\n"
  else
    echo -e "${BL}[Info]${GN} Updating ${BL}$container${CL} : ${GN}$name${CL} - ${YW}[No disk info for ${os}]${CL}\n"
  fi
  case "$os" in
  alpine) pct exec "$container" -- ash -c "apk -U upgrade" ;;
  archlinux) pct exec "$container" -- bash -c "pacman -Syyu --noconfirm" ;;
  fedora | rocky | centos | alma) pct exec "$container" -- bash -c "dnf -y update && dnf -y upgrade" ;;
  ubuntu | debian | devuan) pct exec "$container" -- bash -c "apt-get update 2>/dev/null | grep 'packages.*upgraded'; apt list --upgradable 2>/dev/null | cat && apt-get -yq dist-upgrade 2>&1; rc=\$?; apt-get -yq autoremove 2>&1; apt-get -yq autoclean 2>&1; rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED; exit \$rc" ;;
  opensuse) pct exec "$container" -- bash -c "zypper ref && zypper --non-interactive dup" ;;
  esac 2>&1 | tee "$UPDATE_OUTPUT"
}

# record_failure <ctid> <what> [output file] - adds the output's last error line
function record_failure() {
  local name reason=""
  name=$(pct config "$1" 2>/dev/null | awk '/^hostname:/ {print $2}' || true)
  if [[ -s "${3:-}" ]]; then
    reason=$(sed 's/\x1b\[[0-9;]*[a-zA-Z]//g; s/\r//g' "$3" | grep -E '^(E:|ERROR|Error|error)' | tail -n1 || true)
    [[ -n "$reason" ]] || reason=$(sed 's/\x1b\[[0-9;]*[a-zA-Z]//g; s/\r//g' "$3" | grep -v '^[[:space:]]*$' | tail -n1 || true)
    { echo "CT $1${name:+ ($name)}: $2"; tail -n 20 "$3"; echo; } >>"$RUN_LOG"
  fi
  failed_containers+=("$1${name:+ ($name)}: $2${reason:+ - $reason}")
}

containers_needing_reboot=()
failed_containers=()
header_info
for container in $(pct list | awk '{if(NR>1) print $1}'); do
  if [[ " ${excluded_containers[@]} " =~ " $container " ]]; then
    header_info
    echo -e "${BL}[Info]${GN} Skipping ${BL}$container${CL}"
    sleep 1
  else
    if ! status=$(pct status "$container" 2>&1); then
      record_failure "$container" "pct status failed: $status"
      continue
    fi
    if [ "$SKIP_STOPPED" == "yes" ] && [ "$status" == "status: stopped" ]; then
      header_info
      echo -e "${BL}[Info]${GN} Skipping ${BL}$container${CL}${GN} (not running)${CL}"
      sleep 1
      continue
    fi
    template=$(pct config $container | grep -q "template:" && echo "true" || echo "false")
    if [ "$template" == "false" ] && [ "$status" == "status: stopped" ]; then
      echo -e "${BL}[Info]${GN} Starting${BL} $container ${CL} \n"
      if ! pct start "$container" >"$UPDATE_OUTPUT" 2>&1; then
        cat "$UPDATE_OUTPUT"
        record_failure "$container" "did not start" "$UPDATE_OUTPUT"
        continue
      fi
      echo -e "${BL}[Info]${GN} Waiting For${BL} $container${CL}${GN} To Start ${CL} \n"
      sleep 5
      rc=0
      update_container "$container" || rc=$?
      [ "$rc" -eq 0 ] || record_failure "$container" "update exited with $rc" "$UPDATE_OUTPUT"
      echo -e "${BL}[Info]${GN} Shutting down${BL} $container ${CL} \n"
      pct shutdown $container &
    elif [ "$status" == "status: running" ]; then
      rc=0
      update_container "$container" || rc=$?
      [ "$rc" -eq 0 ] || record_failure "$container" "update exited with $rc" "$UPDATE_OUTPUT"
    fi
    if [ "$status" == "status: running" ]; then
      if pct exec "$container" -- [ -e "/var/run/reboot-required" ]; then
        # Get the container's hostname and add it to the list
        container_hostname=$(pct exec "$container" hostname)
        containers_needing_reboot+=("$container ($container_hostname)")
      fi
      # check if patchmon agent is present in container and run a report if found
      if pct exec "$container" -- [ -e "/usr/local/bin/patchmon-agent" ]; then
        echo -e "${BL}[Info]${GN} patchmon-agent found in ${BL} $container ${CL}, triggering report. \n"
        pct exec "$container" -- "/usr/local/bin/patchmon-agent" "report" || echo -e "${YW}[Warn]${CL} patchmon-agent report failed in $container\n"
      fi
    fi
  fi
done
wait
rm -f "$UPDATE_OUTPUT"
header_info
if [ "${#failed_containers[@]}" -gt 0 ]; then
  echo -e "${RD}The update failed in these containers:${CL}"
  printf '%s\n' "${failed_containers[@]}"
  echo ""
  [ -s "$RUN_LOG" ] && echo -e "Their output: $RUN_LOG\n"
else
  echo -e "${GN}The process is complete, and the containers have been successfully updated.${CL}\n"
fi
if [ "${#containers_needing_reboot[@]}" -gt 0 ]; then
  echo -e "${RD}The following containers require a reboot:${CL}"
  for container_name in "${containers_needing_reboot[@]}"; do
    echo "$container_name"
  done
fi
echo ""
if [ "${#failed_containers[@]}" -gt 0 ]; then
  printf -v CS_ERROR_MSG '%s; ' "${failed_containers[@]}"
  CS_ERROR_MSG="Update failed in ${#failed_containers[@]} container(s): ${CS_ERROR_MSG%; }"
  exit 1
fi
