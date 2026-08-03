#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

APP="all-templates"
APP_TYPE="addon"

if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  if [[ -f /etc/alpine-release ]]; then
    apk update >/dev/null 2>&1
    apk add --no-cache curl >/dev/null 2>&1
  else
    apt-get update >/dev/null 2>&1
    apt-get install -y curl >/dev/null 2>&1
  fi
fi
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "all-templates" "addon"

# Enable error handling; destroy any partially-created container before reporting the error
set -Eeuo pipefail
function _cleanup_on_error() {
  local ec=$? cmd="$BASH_COMMAND"
  [[ -n "${CTID:-}" ]] && cleanup_ctid
  error_handler "$ec" "$cmd"
}
trap '_cleanup_on_error' ERR

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions

function validate_container_id() {
  local ctid="$1"
  # Check if ID is numeric
  if ! [[ "$ctid" =~ ^[0-9]+$ ]]; then
    return 1
  fi
  # Check if config file exists for VM or LXC
  if [[ -f "/etc/pve/qemu-server/${ctid}.conf" ]] || [[ -f "/etc/pve/lxc/${ctid}.conf" ]]; then
    return 1
  fi
  # Check if ID is used in LVM logical volumes
  if lvs --noheadings -o lv_name 2>/dev/null | grep -qE "(^|[-_])${ctid}($|[-_])"; then
    return 1
  fi
  return 0
}
function get_valid_container_id() {
  local suggested_id="${1:-$(pvesh get /cluster/nextid)}"
  while ! validate_container_id "$suggested_id"; do
    suggested_id=$((suggested_id + 1))
  done
  echo "$suggested_id"
}
function cleanup_ctid() {
  if pct status $CTID &>/dev/null; then
    if [ "$(pct status $CTID | awk '{print $2}')" == "running" ]; then
      pct stop $CTID
    fi
    pct destroy $CTID
  fi
}

header_info
require_pve_host

# Stop Proxmox VE Monitor-All if running
if systemctl is-active -q ping-instances.service; then
  systemctl stop ping-instances.service
fi
msg_info "Loading"
pveam update >/dev/null 2>&1
whiptail --backtitle "Proxmox VE Helper Scripts" --title "All Templates" --yesno "This will allow for the creation of one of the many Template LXC Containers. Proceed?" 10 68
TEMPLATE_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  TEMPLATE_MENU+=("$ITEM" "$TAG " "OFF")
done < <(pveam available)
TEMPLATE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "All Template LXCs" --radiolist "\nSelect a Template LXC to create:\n" 16 $((MSG_MAX_LENGTH + 58)) 10 "${TEMPLATE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')
[ -z "$TEMPLATE" ] && {
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "No Template LXC Selected" --msgbox "It appears that no Template LXC container was selected" 10 68
  echo "Done"
  exit 0
}

# Setup script environment
NAME=$(echo "$TEMPLATE" | grep -oE '^[^-]+-[^-]+')
PASS="$(openssl rand -base64 8)"

# Get valid Container ID
CTID=$(pvesh get /cluster/nextid)
if ! validate_container_id "$CTID"; then
  msg_warn "Container ID $CTID is already in use."
  CTID=$(get_valid_container_id "$CTID")
  msg_info "Using next available ID: $CTID"
fi

PCT_OPTIONS="
    -features keyctl=1,nesting=1
    -hostname $NAME
    -tags community-script
    -onboot 0
    -cores 2
    -memory 2048
    -password $PASS
    -net0 name=eth0,bridge=vmbr0,ip=dhcp
    -unprivileged 1
  "
DEFAULT_PCT_OPTIONS=(
  -arch $(dpkg --print-architecture)
)

# Set the CONTENT and CONTENT_LABEL variables
function select_storage() {
  local CLASS=$1
  local CONTENT
  local CONTENT_LABEL
  case $CLASS in
  container)
    CONTENT='rootdir'
    CONTENT_LABEL='Container'
    ;;
  template)
    CONTENT='vztmpl'
    CONTENT_LABEL='Container template'
    ;;
  *)
    msg_error "Invalid storage class."
    exit 112
    ;;
  esac

  # Query all storage locations
  local -a MENU
  while read -r line; do
    local TAG=$(echo $line | awk '{print $1}')
    local TYPE=$(echo $line | awk '{printf "%-10s", $2}')
    local FREE=$(echo $line | numfmt --field 4-6 --from-unit=K --to=iec --format %.2f | awk '{printf( "%9sB", $6)}')
    local ITEM="  Type: $TYPE Free: $FREE "
    local OFFSET=2
    if [[ $((${#ITEM} + $OFFSET)) -gt ${MSG_MAX_LENGTH:-} ]]; then
      local MSG_MAX_LENGTH=$((${#ITEM} + $OFFSET))
    fi
    MENU+=("$TAG" "$ITEM" "OFF")
  done < <(pvesm status -content $CONTENT | awk 'NR>1')

  # Select storage location
  if [ $((${#MENU[@]} / 3)) -eq 0 ]; then
    msg_warn "'$CONTENT_LABEL' needs to be selected for at least one storage location."
    msg_error "Unable to detect valid storage location."
    if [[ "$CONTENT" == "rootdir" ]]; then exit 119; else exit 120; fi
  elif [ $((${#MENU[@]} / 3)) -eq 1 ]; then
    printf ${MENU[0]}
  else
    local STORAGE
    while [ -z "${STORAGE:+x}" ]; do
      STORAGE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Storage Pools" --radiolist \
        "Which storage pool would you like to use for the ${CONTENT_LABEL,,}?\n\n" \
        16 $(($MSG_MAX_LENGTH + 23)) 6 \
        "${MENU[@]}" 3>&1 1>&2 2>&3) || {
        msg_error "Menu aborted."
        exit 254
      }
    done
    printf $STORAGE
  fi
}

# Get template storage
TEMPLATE_STORAGE=$(select_storage template)
msg_info "Using '$TEMPLATE_STORAGE' for template storage."

# Get container storage
CONTAINER_STORAGE=$(select_storage container)
msg_info "Using '$CONTAINER_STORAGE' for container storage."

# Download template
msg_info "Downloading LXC template (Patience)"
pveam download $TEMPLATE_STORAGE $TEMPLATE >/dev/null || {
  msg_error "A problem occured while downloading the LXC template."
  exit 222
}
msg_ok "Downloaded LXC template"

# Create variable for 'pct' options
PCT_OPTIONS=(${PCT_OPTIONS[@]:-${DEFAULT_PCT_OPTIONS[@]}})
[[ " ${PCT_OPTIONS[*]} " =~ " -rootfs " ]] || PCT_OPTIONS+=(-rootfs $CONTAINER_STORAGE:${PCT_DISK_SIZE:-8})

# Create LXC
msg_info "Creating LXC container"
pct create $CTID ${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE} "${PCT_OPTIONS[@]}" >/dev/null || {
  msg_error "A problem occured while trying to create container."
  exit 209
}
msg_ok "Created LXC container"

# Save password
echo "$NAME password: ${PASS}" >>~/$NAME.creds # file is located in the Proxmox root directory

# Start container
msg_info "Starting LXC Container"
pct start "$CTID"
sleep 5
msg_ok "Started LXC Container"

# Get container IP
set +Eeuo pipefail
max_attempts=5
attempt=1
IP=""
while [[ $attempt -le $max_attempts ]]; do
  IP=$(pct exec $CTID ip a show dev eth0 | grep -oP 'inet \K[^/]+')
  if [[ -n $IP ]]; then
    break
  else
    msg_warn "Attempt $attempt: IP address not found. Pausing for 5 seconds..."
    sleep 5
    ((attempt++))
  fi
done

if [[ -z $IP ]]; then
  msg_warn "Maximum number of attempts reached. IP address not found."
  IP="NOT FOUND"
fi

set -Eeuo pipefail
# Start Proxmox VE Monitor-All if available
if [[ -f /etc/systemd/system/ping-instances.service ]]; then
  systemctl start ping-instances.service
fi

# Success message
echo
msg_ok "LXC container '$CTID' was successfully created, and its IP address is ${IP}."
echo
echo -e "${YW}Proceed to the LXC console to complete the setup.${CL}"
echo
echo -e "${YW}login: root${CL}"
echo -e "${YW}password: $PASS${CL}"
echo
