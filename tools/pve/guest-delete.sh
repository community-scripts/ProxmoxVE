#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    ____                                          ______                __     ____       __     __
   / __ \_________  _  ______ ___  ____  _  __   / ____/_  _____  _____/ /_   / __ \___  / /__  / /____
  / /_/ / ___/ __ \| |/_/ __ `__ \/ __ \| |/_/  / / __/ / / / _ \/ ___/ __/  / / / / _ \/ / _ \/ __/ _ \
 / ____/ /  / /_/ />  </ / / / / / /_/ />  <   / /_/ / /_/ /  __(__  ) /_   / /_/ /  __/ /  __/ /_/  __/
/_/   /_/   \____/_/|_/_/ /_/ /_/\____/_/|_|   \____/\__,_/\___/____/\__/  /_____/\___/_/\___/\__/\___/

EOF
}

spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while ps -p $pid >/dev/null; do
    printf " [%c]  " "$spinstr"
    spinstr=${spinstr#?}${spinstr%"${spinstr#?}"}
    sleep $delay
    printf "\r"
  done
  printf "    \r"
}

set -eEuo pipefail
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
TAB="  "
CM="${TAB}✔️${TAB}${CL}"

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "guest-delete" "pve"

GUEST_LOG=$(mktemp)
trap 'rm -f "$GUEST_LOG"' EXIT

# pct and qm differ in both their subcommands and their list layout, so every
# guest carries its type from the menu through to the destroy call.
stop_guest() {
  local type=$1 id=$2 pid
  if [ "$type" == "ct" ]; then
    pct stop "$id" >"$GUEST_LOG" 2>&1 &
  else
    qm stop "$id" >"$GUEST_LOG" 2>&1 &
  fi
  pid=$!
  spinner "$pid"
  wait "$pid" || true
}

destroy_guest() {
  local type=$1 id=$2 pid
  if [ "$type" == "ct" ]; then
    pct destroy "$id" -f >"$GUEST_LOG" 2>&1 &
  else
    qm destroy "$id" --purge --destroy-unreferenced-disks >"$GUEST_LOG" 2>&1 &
  fi
  pid=$!
  spinner "$pid"
  wait "$pid"
}

header_info
echo "Loading..."
whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE Guest Deletion" --yesno "This will delete LXC containers and/or VMs. Proceed?" 10 58

NODE=$(hostname)
containers=$(pct list 2>/dev/null | tail -n +2 || true)
vms=$(qm list 2>/dev/null | tail -n +2 || true)

if [ -z "$containers" ] && [ -z "$vms" ]; then
  whiptail --title "Guest Delete" --msgbox "No LXC containers or VMs available!" 10 60
  exit 234
fi

declare -A GUEST_TYPE=()
menu_items=()
FORMAT="%-4s %-20s %-10s"

if [ -n "$containers" ]; then
  menu_items+=("ALL-CT" "$(printf "$FORMAT" "CT" "Delete ALL containers" "")" "OFF")
  while read -r line; do
    [ -z "$line" ] && continue
    # pct list: VMID Status [Lock] Name -- Lock is usually blank, so take the
    # name from the end of the row rather than a fixed column.
    container_id=$(awk '{print $1}' <<<"$line")
    container_status=$(awk '{print $2}' <<<"$line")
    container_name=$(awk '{print $NF}' <<<"$line")
    GUEST_TYPE[$container_id]="ct"
    menu_items+=("$container_id" "$(printf "$FORMAT" "CT" "$container_name" "$container_status")" "OFF")
  done <<<"$containers"
fi

if [ -n "$vms" ]; then
  menu_items+=("ALL-VM" "$(printf "$FORMAT" "VM" "Delete ALL VMs" "")" "OFF")
  while read -r line; do
    [ -z "$line" ] && continue
    # qm list: VMID NAME STATUS MEM(MB) BOOTDISK(GB) PID
    vm_id=$(awk '{print $1}' <<<"$line")
    vm_name=$(awk '{print $2}' <<<"$line")
    vm_status=$(awk '{print $3}' <<<"$line")
    GUEST_TYPE[$vm_id]="vm"
    menu_items+=("$vm_id" "$(printf "$FORMAT" "VM" "$vm_name" "$vm_status")" "OFF")
  done <<<"$vms"
fi

CHOICES=$(whiptail --title "Guest Delete" \
  --checklist "Select LXC containers and VMs to delete:" 25 70 13 \
  "${menu_items[@]}" 3>&2 2>&1 1>&3 || true)

if [ -z "$CHOICES" ]; then
  whiptail --title "Guest Delete" \
    --msgbox "No guests selected!" 10 60
  exit 0
fi

read -p "Delete guests manually or automatically? (Default: manual) m/a: " DELETE_MODE
DELETE_MODE=${DELETE_MODE:-m}

# Expand the ALL entries, keeping each ID once so selecting ALL alongside a
# single guest does not try to destroy that guest twice.
expanded_ids=""
for choice in $(echo "$CHOICES" | tr -d '"' | tr -s ' ' '\n'); do
  case "$choice" in
  ALL-CT) expanded_ids+=$'\n'$(awk '{print $1}' <<<"$containers") ;;
  ALL-VM) expanded_ids+=$'\n'$(awk '{print $1}' <<<"$vms") ;;
  *) expanded_ids+=$'\n'"$choice" ;;
  esac
done
selected_ids=$(echo "$expanded_ids" | sed '/^$/d' | awk '!seen[$0]++')

for guest_id in $selected_ids; do
  guest_type="${GUEST_TYPE[$guest_id]:-}"
  if [ -z "$guest_type" ]; then
    echo -e "${BL}[Info]${RD} Skipping unknown guest $guest_id...${CL}"
    continue
  fi

  if [ "$guest_type" == "ct" ]; then
    label="container $guest_id"
  else
    label="VM $guest_id"
  fi

  if [[ "$DELETE_MODE" == "a" ]]; then
    echo -e "${BL}[Info]${GN} Automatically deleting $label...${CL}"
  else
    read -p "Delete $label? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
      echo -e "${BL}[Info]${RD} Skipping $label...${CL}"
      continue
    fi
    echo -e "${BL}[Info]${GN} Deleting $label...${CL}"
  fi

  # Stop only once the deletion is confirmed, so declining leaves a running
  # guest running instead of powering it off on the way out.
  if [ "$guest_type" == "ct" ]; then
    status=$(pct status "$guest_id" 2>/dev/null || echo "unknown")
  else
    status=$(qm status "$guest_id" 2>/dev/null || echo "unknown")
  fi

  if [ "$status" == "status: running" ]; then
    echo -e "${BL}[Info]${GN} Stopping $label...${CL}"
    stop_guest "$guest_type" "$guest_id"
    echo -e "${BL}[Info]${GN} ${label^} stopped.${CL}"
  fi

  if destroy_guest "$guest_type" "$guest_id"; then
    echo -e "${CM}${GN}${label^} deleted.${CL}"
  else
    whiptail --title "Error" --msgbox "Failed to delete ${label}.\n\n$(tail -n 5 "$GUEST_LOG")" 15 70
  fi
done

header_info
echo -e "${GN}Deletion process completed.${CL}\n"
