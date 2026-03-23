#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

# Source shared libraries
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
load_functions
catch_errors

APP="TurnKey LXC"
NSAPP="turnkey"
DIAGNOSTICS="no"
METHOD="default"
RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
EXECUTION_ID="${RANDOM_UUID}"

header_info() {
  clear
  cat <<"EOF"
 ______              __ __           __   _  _______
/_  __/_ _________  / //_/__ __ __  / /  | |/_/ ___/
 / / / // / __/ _ \/ ,< / -_) // / / /___>  </ /__
/_/  \_,_/_/ /_//_/_/|_|\__/\_, / /____/_/|_|\___/
                           /___/
EOF
}

# Validate if a container ID is available (cluster-aware)
validate_container_id() {
  local ctid="$1"
  [[ "$ctid" =~ ^[0-9]+$ ]] || return 1

  # Cluster-wide check via pvesh
  if command -v pvesh &>/dev/null; then
    local cluster_ids
    cluster_ids=$(pvesh get /cluster/resources --type vm --output-format json 2>/dev/null |
      grep -oP '"vmid":\s*\K[0-9]+' 2>/dev/null || true)
    if [[ -n "$cluster_ids" ]] && echo "$cluster_ids" | grep -qw "$ctid"; then
      return 1
    fi
  fi

  # Local fallback
  if [[ -f "/etc/pve/qemu-server/${ctid}.conf" ]] || [[ -f "/etc/pve/lxc/${ctid}.conf" ]]; then
    return 1
  fi

  # Check all cluster nodes
  if [[ -d "/etc/pve/nodes" ]]; then
    for node_dir in /etc/pve/nodes/*/; do
      if [[ -f "${node_dir}qemu-server/${ctid}.conf" ]] || [[ -f "${node_dir}lxc/${ctid}.conf" ]]; then
        return 1
      fi
    done
  fi

  # Check LVM volumes
  if lvs --noheadings -o lv_name 2>/dev/null | grep -qE "(^|[-_])${ctid}($|[-_])"; then
    return 1
  fi
  return 0
}

get_valid_container_id() {
  local suggested_id="${1:-$(pvesh get /cluster/nextid 2>/dev/null || echo 100)}"
  while ! validate_container_id "$suggested_id"; do
    suggested_id=$((suggested_id + 1))
  done
  echo "$suggested_id"
}

cleanup_ctid() {
  if pct status "$CTID" &>/dev/null; then
    if [[ "$(pct status "$CTID" | awk '{print $2}')" == "running" ]]; then
      pct stop "$CTID"
    fi
    pct destroy "$CTID"
  fi
}

select_storage() {
  local class="$1" content content_label
  case "$class" in
  container)
    content='rootdir'
    content_label='Container'
    ;;
  template)
    content='vztmpl'
    content_label='Container template'
    ;;
  *)
    msg_error "Invalid storage class '$class'"
    return 1
    ;;
  esac

  local -a MENU=()
  local MSG_MAX_LENGTH=0

  while read -r line; do
    local TAG TYPE FREE ITEM OFFSET=2
    TAG=$(echo "$line" | awk '{print $1}')
    TYPE=$(echo "$line" | awk '{printf "%-10s", $2}')
    FREE=$(echo "$line" | numfmt --field 4-6 --from-unit=K --to=iec --format %.2f | awk '{printf( "%9sB", $6)}')
    ITEM="  Type: $TYPE Free: $FREE "
    ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=$((${#ITEM} + OFFSET))
    MENU+=("$TAG" "$ITEM" "OFF")
  done < <(pvesm status -content "$content" | awk 'NR>1')

  if [[ $((${#MENU[@]} / 3)) -eq 0 ]]; then
    msg_error "'$content_label' needs to be selected for at least one storage location."
    return 1
  elif [[ $((${#MENU[@]} / 3)) -eq 1 ]]; then
    printf '%s' "${MENU[0]}"
  else
    local STORAGE
    while [[ -z "${STORAGE:+x}" ]]; do
      STORAGE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Storage Pools" --radiolist \
        "Which storage pool for the ${content_label,,}?\n\n" \
        16 $((MSG_MAX_LENGTH + 23)) 6 \
        "${MENU[@]}" 3>&1 1>&2 2>&3) || exit_script
    done
    printf '%s' "$STORAGE"
  fi
}

# ==============================================================================
# MAIN
# ==============================================================================

# Cleanup on error: destroy container and restart monitor
turnkey_cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]] && [[ -n "${CTID:-}" ]]; then
    cleanup_ctid 2>/dev/null || true
  fi
  if [[ -f /etc/systemd/system/ping-instances.service ]]; then
    systemctl start ping-instances.service 2>/dev/null || true
  fi
}
trap turnkey_cleanup EXIT

# Stop Proxmox VE Monitor-All if running
if systemctl is-active -q ping-instances.service; then
  systemctl stop ping-instances.service
fi

pve_check
shell_check
root_check

# Read diagnostics preference (same logic as build.func diagnostics_check)
DIAG_CONFIG="/usr/local/community-scripts/diagnostics"
if [[ -f "$DIAG_CONFIG" ]]; then
  DIAGNOSTICS=$(awk -F '=' '/^DIAGNOSTICS/ {print $2}' "$DIAG_CONFIG") || true
  DIAGNOSTICS="${DIAGNOSTICS:-no}"
fi

header_info
whiptail --backtitle "Proxmox VE Helper Scripts" --title "TurnKey LXCs" --yesno \
  "This will allow for the creation of one of the many TurnKey LXC Containers. Proceed?" 10 68 || exit_script

# Build TurnKey selection menu
TURNKEY_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=$((${#ITEM} + OFFSET))
  TURNKEY_MENU+=("$TAG" "$ITEM " "OFF")
done < <(
  cat <<EOF
ansible Ansible
bookstack BookStack
core Core
faveo-helpdesk Faveo Helpdesk
fileserver File Server
gallery Gallery
gameserver Game Server
gitea Gitea
gitlab GitLab
invoice-ninja Invoice Ninja
mediaserver Media Server
nextcloud Nextcloud
observium Observium
odoo Odoo
openldap OpenLDAP
openvpn OpenVPN
owncloud ownCloud
phpbb phpBB
torrentserver Torrent Server
wireguard WireGuard
wordpress Wordpress
zoneminder ZoneMinder
EOF
)

turnkey=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "TurnKey LXCs" --radiolist \
  "\nSelect a TurnKey LXC to create:\n" 16 $((MSG_MAX_LENGTH + 58)) 6 \
  "${TURNKEY_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit_script

if [[ -z "$turnkey" ]]; then
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "No TurnKey LXC Selected" \
    --msgbox "It appears that no TurnKey LXC container was selected" 10 68
  exit_script
fi

# Generate random password
PASS="$(openssl rand -base64 8)"

# Prompt for Container ID
NEXT_ID=$(pvesh get /cluster/nextid 2>/dev/null || echo 100)
while true; do
  CTID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Container ID" \
    --inputbox "Enter the container ID..." 8 40 "$NEXT_ID" 3>&1 1>&2 2>&3) || exit_script

  if [[ -z "$CTID" ]]; then
    msg_error "No Container ID selected"
    exit_script
  fi

  if ! validate_container_id "$CTID"; then
    SUGGESTED_ID=$(get_valid_container_id "$CTID")
    if whiptail --backtitle "Proxmox VE Helper Scripts" --title "ID Already In Use" --yesno \
      "Container/VM ID $CTID is already in use.\n\nWould you like to use the next available ID ($SUGGESTED_ID)?" 10 58; then
      CTID="$SUGGESTED_ID"
      break
    fi
  else
    break
  fi
done

# Prompt for Hostname
HOST_NAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Hostname" \
  --inputbox "Enter the container hostname..." 8 40 "turnkey-${turnkey}" 3>&1 1>&2 2>&3) || exit_script

# Container options
PCT_OPTIONS=(
  -features keyctl=1,nesting=1
  -hostname "$HOST_NAME"
  -tags community-script
  -onboot 1
  -cores 2
  -memory 2048
  -password "$PASS"
  -net0 name=eth0,bridge=vmbr0,ip=dhcp
  -unprivileged 1
  -arch "$(dpkg --print-architecture)"
)

# Storage selection
TEMPLATE_STORAGE=$(select_storage template) || {
  msg_error "Failed to select template storage"
  exit 1
}
msg_ok "Using '${BL}${TEMPLATE_STORAGE}${CL}' for template storage"

CONTAINER_STORAGE=$(select_storage container) || {
  msg_error "Failed to select container storage"
  exit 1
}
msg_ok "Using '${BL}${CONTAINER_STORAGE}${CL}' for container storage"

# Update template catalog
msg_info "Updating LXC template list"
pveam update >/dev/null
msg_ok "Updated LXC template list"

# Find latest TurnKey template
mapfile -t TEMPLATES < <(pveam available -section turnkeylinux | awk -v tk="${turnkey}" '$0 ~ tk {print $2}' | sort -t - -k 2 -V)
if [[ ${#TEMPLATES[@]} -eq 0 ]]; then
  msg_error "Unable to find a template when searching for '${turnkey}'"
  exit 1
fi
TEMPLATE="${TEMPLATES[-1]}"

# Download template if not already cached
if ! pveam list "$TEMPLATE_STORAGE" | grep -q "$TEMPLATE"; then
  msg_info "Downloading LXC template"
  pveam download "$TEMPLATE_STORAGE" "$TEMPLATE" >/dev/null || {
    msg_error "Failed to download LXC template '${TEMPLATE}'"
    exit 1
  }
  msg_ok "Downloaded LXC template"
fi

# Add rootfs if not specified
[[ " ${PCT_OPTIONS[*]} " =~ " -rootfs " ]] || PCT_OPTIONS+=(-rootfs "${CONTAINER_STORAGE}:${PCT_DISK_SIZE:-8}")

# Set telemetry variables for the selected turnkey
NSAPP="turnkey-${turnkey}"
CT_TYPE=1
DISK_SIZE="${PCT_DISK_SIZE:-8}"
CORE_COUNT=2
RAM_SIZE=2048
var_os="turnkey"
var_version="${turnkey}"

# Report installation start to telemetry
post_to_api

# Create LXC container
msg_info "Creating LXC container"
pct create "$CTID" "${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE}" "${PCT_OPTIONS[@]}" >/dev/null || {
  msg_error "Failed to create container"
  exit 1
}
msg_ok "Created LXC container (ID: ${BL}${CTID}${CL})"

# Save credentials securely
CREDS_FILE=~/turnkey-${turnkey}.creds
echo "TurnKey ${turnkey} password: ${PASS}" >>"$CREDS_FILE"
chmod 600 "$CREDS_FILE"

# Configure TUN device access for VPN-based turnkeys
TUN_DEVICE_REQUIRED=("openvpn")
if printf '%s\n' "${TUN_DEVICE_REQUIRED[@]}" | grep -qw "${turnkey}"; then
  msg_info "Configuring TUN device access for ${turnkey}"
  {
    echo "lxc.cgroup2.devices.allow: c 10:200 rwm"
    echo "lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file 0 0"
  } >>"/etc/pve/lxc/${CTID}.conf"
  msg_ok "TUN device access configured"
  sleep 5
fi

# Start container
msg_info "Starting LXC container"
pct start "$CTID"
msg_ok "Started LXC container"
sleep 10

# Detect container IP
msg_info "Detecting IP address"
IP=""
for attempt in $(seq 1 5); do
  IP=$(pct exec "$CTID" -- ip -4 a show dev eth0 2>/dev/null | grep -oP 'inet \K[^/]+' || true)
  if [[ -n "$IP" ]]; then
    break
  fi
  [[ $attempt -lt 5 ]] && sleep 5
done

if [[ -z "$IP" ]]; then
  msg_warn "IP address not found after 5 attempts"
  IP="NOT FOUND"
else
  msg_ok "IP address: ${BL}${IP}${CL}"
fi

# Report success to telemetry
post_update_to_api "done" "none"

# Success summary
header_info
echo
msg_ok "TurnKey ${BL}${turnkey}${CL} LXC container '${BL}${CTID}${CL}' was successfully created."
echo
echo -e "  ${TAB}${YW}IP Address:${CL}  ${BL}${IP}${CL}"
echo -e "  ${TAB}${YW}Login:${CL}       ${GN}root${CL}"
echo -e "  ${TAB}${YW}Password:${CL}    ${GN}${PASS}${CL}"
echo
echo -e "  ${TAB}Proceed to the LXC console to complete the TurnKey setup."
echo -e "  ${TAB}Credentials stored in: ${BL}~/turnkey-${turnkey}.creds${CL}"
echo
