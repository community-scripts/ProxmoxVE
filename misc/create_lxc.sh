#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

# This sets verbose mode if the global variable is set to "yes"
# if [ "$VERBOSE" == "yes" ]; then set -x; fi

if command -v curl >/dev/null 2>&1; then
  source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
  load_functions
  #echo "(create-lxc.sh) Loaded core.func via curl"
elif command -v wget >/dev/null 2>&1; then
  source <(wget -qO- https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
  load_functions
  #echo "(create-lxc.sh) Loaded core.func via wget"
fi

# This sets error handling options and defines the error_handler function to handle errors
set -Eeuo pipefail
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
trap on_exit EXIT
trap on_interrupt INT
trap on_terminate TERM

function on_exit() {
  local exit_code="$?"
  [[ -n "${lockfile:-}" && -e "$lockfile" ]] && rm -f "$lockfile"
  exit "$exit_code"
}

function error_handler() {
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  printf "\e[?25h"
  echo -e "\n${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}\n"
  exit "$exit_code"
}

function on_interrupt() {
  echo -e "\n${RD}Interrupted by user (SIGINT)${CL}"
  exit 130
}

function on_terminate() {
  echo -e "\n${RD}Terminated by signal (SIGTERM)${CL}"
  exit 143
}

function exit_script() {
  clear
  printf "\e[?25h"
  echo -e "\n${CROSS}${RD}User exited script${CL}\n"
  kill 0
  exit 1
}

function check_storage_support() {
  local CONTENT="$1"
  local -a VALID_STORAGES=()
  while IFS= read -r line; do
    local STORAGE_NAME
    STORAGE_NAME=$(awk '{print $1}' <<<"$line")
    [[ -z "$STORAGE_NAME" ]] && continue
    VALID_STORAGES+=("$STORAGE_NAME")
  done < <(pvesm status -content "$CONTENT" 2>/dev/null | awk 'NR>1')

  [[ ${#VALID_STORAGES[@]} -gt 0 ]]
}

# This function selects a storage pool for a given content type (e.g., rootdir, vztmpl).
function select_storage() {
  local CLASS=$1 CONTENT CONTENT_LABEL

  case $CLASS in
  container)
    CONTENT='rootdir'
    CONTENT_LABEL='Container'
    ;;
  template)
    CONTENT='vztmpl'
    CONTENT_LABEL='Container template'
    ;;
  iso)
    CONTENT='iso'
    CONTENT_LABEL='ISO image'
    ;;
  images)
    CONTENT='images'
    CONTENT_LABEL='VM Disk image'
    ;;
  backup)
    CONTENT='backup'
    CONTENT_LABEL='Backup'
    ;;
  snippets)
    CONTENT='snippets'
    CONTENT_LABEL='Snippets'
    ;;
  *)
    msg_error "Invalid storage class '$CLASS'"
    return 1
    ;;
  esac

  # Check for preset STORAGE variable
  if [ "$CONTENT" = "rootdir" ] && [ -n "${STORAGE:-}" ]; then
    if pvesm status -content "$CONTENT" | awk 'NR>1 {print $1}' | grep -qx "$STORAGE"; then
      STORAGE_RESULT="$STORAGE"
      msg_info "Using preset storage: $STORAGE_RESULT for $CONTENT_LABEL"
      return 0
    else
      msg_error "Preset storage '$STORAGE' is not valid for content type '$CONTENT'."
      return 2
    fi
  fi

  local -A STORAGE_MAP
  local -a MENU
  local COL_WIDTH=0

  while read -r TAG TYPE _ TOTAL USED FREE _; do
    [[ -n "$TAG" && -n "$TYPE" ]] || continue
    local STORAGE_NAME="$TAG"
    local DISPLAY="${STORAGE_NAME} (${TYPE})"
    local USED_FMT=$(numfmt --to=iec --from-unit=K --format %.1f <<<"$USED")
    local FREE_FMT=$(numfmt --to=iec --from-unit=K --format %.1f <<<"$FREE")
    local INFO="Free: ${FREE_FMT}B  Used: ${USED_FMT}B"
    STORAGE_MAP["$DISPLAY"]="$STORAGE_NAME"
    MENU+=("$DISPLAY" "$INFO" "OFF")
    ((${#DISPLAY} > COL_WIDTH)) && COL_WIDTH=${#DISPLAY}
  done < <(pvesm status -content "$CONTENT" | awk 'NR>1')

  if [ ${#MENU[@]} -eq 0 ]; then
    msg_error "No storage found for content type '$CONTENT'."
    return 2
  fi

  if [ $((${#MENU[@]} / 3)) -eq 1 ]; then
    STORAGE_RESULT="${STORAGE_MAP[${MENU[0]}]}"
    STORAGE_INFO="${MENU[1]}"
    return 0
  fi

  local WIDTH=$((COL_WIDTH + 42))
  while true; do
    local DISPLAY_SELECTED
    DISPLAY_SELECTED=$(whiptail --backtitle "Proxmox VE Helper Scripts" \
      --title "Storage Pools" \
      --radiolist "Which storage pool for ${CONTENT_LABEL,,}?\n(Spacebar to select)" \
      16 "$WIDTH" 6 "${MENU[@]}" 3>&1 1>&2 2>&3)

    # Cancel or ESC
    [[ $? -ne 0 ]] && exit_script

    # Strip trailing whitespace or newline (important for storages like "storage (dir)")
    DISPLAY_SELECTED=$(sed 's/[[:space:]]*$//' <<<"$DISPLAY_SELECTED")

    if [[ -z "$DISPLAY_SELECTED" || -z "${STORAGE_MAP[$DISPLAY_SELECTED]+_}" ]]; then
      whiptail --msgbox "No valid storage selected. Please try again." 8 58
      continue
    fi

    STORAGE_RESULT="${STORAGE_MAP[$DISPLAY_SELECTED]}"
    for ((i = 0; i < ${#MENU[@]}; i += 3)); do
      if [[ "${MENU[$i]}" == "$DISPLAY_SELECTED" ]]; then
        STORAGE_INFO="${MENU[$i + 1]}"
        break
      fi
    done
    return 0
  done
}

# Test if required variables are set
[[ "${CTID:-}" ]] || {
  msg_error "You need to set 'CTID' variable."
  exit 203
}
[[ "${PCT_OSTYPE:-}" ]] || {
  msg_error "You need to set 'PCT_OSTYPE' variable."
  exit 204
}

# Test if ID is valid
[ "$CTID" -ge "100" ] || {
  msg_error "ID cannot be less than 100."
  exit 205
}

# Test if ID is in use
if qm status "$CTID" &>/dev/null || pct status "$CTID" &>/dev/null; then
  echo -e "ID '$CTID' is already in use."
  unset CTID
  msg_error "Cannot use ID that is already in use."
  exit 206
fi

# This checks for the presence of valid Container Storage and Template Storage locations
msg_info "Validating storage"
if ! check_storage_support "rootdir"; then
  msg_error "No valid storage found for 'rootdir' [Container]"
  exit 1
fi
if ! check_storage_support "vztmpl"; then
  msg_error "No valid storage found for 'vztmpl' [Template]"
  exit 1
fi

#msg_info "Checking template storage"
while true; do
  if select_storage template; then
    TEMPLATE_STORAGE="$STORAGE_RESULT"
    TEMPLATE_STORAGE_INFO="$STORAGE_INFO"
    msg_ok "Storage ${BL}$TEMPLATE_STORAGE${CL} ($TEMPLATE_STORAGE_INFO) [Template]"
    break
  fi
done

while true; do
  if select_storage container; then
    CONTAINER_STORAGE="$STORAGE_RESULT"
    CONTAINER_STORAGE_INFO="$STORAGE_INFO"
    msg_ok "Storage ${BL}$CONTAINER_STORAGE${CL} ($CONTAINER_STORAGE_INFO) [Container]"
    break
  fi
done

# Check free space on selected container storage
STORAGE_FREE=$(pvesm status | awk -v s="$CONTAINER_STORAGE" '$1 == s { print $6 }')
REQUIRED_KB=$((${PCT_DISK_SIZE:-8} * 1024 * 1024))
if [ "$STORAGE_FREE" -lt "$REQUIRED_KB" ]; then
  msg_error "Not enough space on '$CONTAINER_STORAGE'. Needed: ${PCT_DISK_SIZE:-8}G."
  exit 214
fi

# Check Cluster Quorum if in Cluster
if [ -f /etc/pve/corosync.conf ]; then
  msg_info "Checking cluster quorum"
  if ! pvecm status | awk -F':' '/^Quorate/ { exit ($2 ~ /Yes/) ? 0 : 1 }'; then

    msg_error "Cluster is not quorate. Start all nodes or configure quorum device (QDevice)."
    exit 210
  fi
  msg_ok "Cluster is quorate"
fi

# Update LXC template list
TEMPLATE_SEARCH="${PCT_OSTYPE}-${PCT_OSVERSION:-}"
case "$PCT_OSTYPE" in
debian | ubuntu)
  TEMPLATE_PATTERN="-standard_"
  ;;
alpine | fedora | rocky | centos)
  TEMPLATE_PATTERN="-default_"
  ;;
*)
  TEMPLATE_PATTERN=""
  ;;
esac

# 1. Check local templates first
msg_info "Searching for template '$TEMPLATE_SEARCH'"
mapfile -t TEMPLATES < <(
  pveam list "$TEMPLATE_STORAGE" |
    awk -v s="$TEMPLATE_SEARCH" -v p="$TEMPLATE_PATTERN" '$1 ~ s && $1 ~ p {print $1}' |
    sed 's/.*\///' | sort -t - -k 2 -V
)

if [ ${#TEMPLATES[@]} -gt 0 ]; then
  TEMPLATE_SOURCE="local"
else
  msg_info "No local template found, checking online repository"
  pveam update >/dev/null 2>&1
  mapfile -t TEMPLATES < <(
    pveam update >/dev/null 2>&1 &&
      pveam available -section system |
      sed -n "s/.*\($TEMPLATE_SEARCH.*$TEMPLATE_PATTERN.*\)/\1/p" |
        sort -t - -k 2 -V
  )
  TEMPLATE_SOURCE="online"
fi

TEMPLATE="${TEMPLATES[-1]}"
TEMPLATE_PATH="$(pvesm path $TEMPLATE_STORAGE:vztmpl/$TEMPLATE 2>/dev/null ||
  echo "/var/lib/vz/template/cache/$TEMPLATE")"
msg_ok "Template ${BL}$TEMPLATE${CL} [$TEMPLATE_SOURCE]"

# 4. Validate template (exists & not corrupted)
TEMPLATE_VALID=1

if [ ! -s "$TEMPLATE_PATH" ]; then
  TEMPLATE_VALID=0
elif ! tar --use-compress-program=zstdcat -tf "$TEMPLATE_PATH" >/dev/null 2>&1; then
  TEMPLATE_VALID=0
fi

if [ "$TEMPLATE_VALID" -eq 0 ]; then
  msg_warn "Template $TEMPLATE is missing or corrupted. Re-downloading."
  [[ -f "$TEMPLATE_PATH" ]] && rm -f "$TEMPLATE_PATH"
  for attempt in {1..3}; do
    msg_info "Attempt $attempt: Downloading LXC template..."
    if pveam download "$TEMPLATE_STORAGE" "$TEMPLATE" >/dev/null 2>&1; then
      msg_ok "Template download successful."
      break
    fi
    if [ $attempt -eq 3 ]; then
      msg_error "Failed after 3 attempts. Please check network access or manually run:\n  pveam download $TEMPLATE_STORAGE $TEMPLATE"
      exit 208
    fi
    sleep $((attempt * 5))
  done
fi

msg_info "Creating LXC Container"
# Check and fix subuid/subgid
grep -q "root:100000:65536" /etc/subuid || echo "root:100000:65536" >>/etc/subuid
grep -q "root:100000:65536" /etc/subgid || echo "root:100000:65536" >>/etc/subgid

# Combine all options
PCT_OPTIONS=(${PCT_OPTIONS[@]:-${DEFAULT_PCT_OPTIONS[@]}})
[[ " ${PCT_OPTIONS[@]} " =~ " -rootfs " ]] || PCT_OPTIONS+=(-rootfs "$CONTAINER_STORAGE:${PCT_DISK_SIZE:-8}")

# Secure creation of the LXC container with lock and template check
lockfile="/tmp/template.${TEMPLATE}.lock"
exec 9>"$lockfile" || {
  msg_error "Failed to create lock file '$lockfile'."
  exit 200
}
flock -w 60 9 || {
  msg_error "Timeout while waiting for template lock"
  exit 211
}

if ! pct create "$CTID" "${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE}" "${PCT_OPTIONS[@]}" &>/dev/null; then
  msg_error "Container creation failed. Checking if template is corrupted or incomplete."

  if [[ ! -s "$TEMPLATE_PATH" || "$(stat -c%s "$TEMPLATE_PATH")" -lt 1000000 ]]; then
    msg_error "Template file too small or missing – re-downloading."
    rm -f "$TEMPLATE_PATH"
  elif ! zstdcat "$TEMPLATE_PATH" | tar -tf - &>/dev/null; then
    msg_error "Template appears to be corrupted – re-downloading."
    rm -f "$TEMPLATE_PATH"
  else
    msg_error "Template is valid, but container creation still failed."
    exit 209
  fi

  # Retry download
  for attempt in {1..3}; do
    msg_info "Attempt $attempt: Re-downloading template..."
    if timeout 120 pveam download "$TEMPLATE_STORAGE" "$TEMPLATE" >/dev/null; then
      msg_ok "Template re-download successful."
      break
    fi
    if [ "$attempt" -eq 3 ]; then
      msg_error "Three failed attempts. Aborting."
      exit 208
    fi
    sleep $((attempt * 5))
  done

  sleep 1 # I/O-Sync-Delay
  msg_ok "Re-downloaded LXC Template"
fi

if ! pct list | awk '{print $1}' | grep -qx "$CTID"; then
  msg_error "Container ID $CTID not listed in 'pct list' – unexpected failure."
  exit 215
fi

if ! grep -q '^rootfs:' "/etc/pve/lxc/$CTID.conf"; then
  msg_error "RootFS entry missing in container config – storage not correctly assigned."
  exit 216
fi

if grep -q '^hostname:' "/etc/pve/lxc/$CTID.conf"; then
  CT_HOSTNAME=$(grep '^hostname:' "/etc/pve/lxc/$CTID.conf" | awk '{print $2}')
  if [[ ! "$CT_HOSTNAME" =~ ^[a-z0-9-]+$ ]]; then
    msg_warn "Hostname '$CT_HOSTNAME' contains invalid characters – may cause issues with networking or DNS."
  fi
fi

msg_ok "LXC Container ${BL}$CTID${CL} ${GN}was successfully created."
