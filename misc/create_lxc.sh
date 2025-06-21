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

# This function handles errors
function error_handler() {
  printf "\e[?25h"
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  echo -e "\n$error_message\n"
  exit 200
}

# This checks for the presence of valid Container Storage and Template Storage locations
msg_info "Validating Storage"
VALIDCT=$(pvesm status -content rootdir | awk 'NR>1')
if [ -z "$VALIDCT" ]; then
  msg_error "Unable to detect a valid Container Storage location."
  exit 1
fi
VALIDTMP=$(pvesm status -content vztmpl | awk 'NR>1')
if [ -z "$VALIDTMP" ]; then
  msg_error "Unable to detect a valid Template Storage location."
  exit 1
fi

# This function is used to select the storage class and determine the corresponding storage content type and label.
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
  *) false || {
    msg_error "Invalid storage class."
    exit 201
  } ;;
  esac

  # Collect storage options
  local -a MENU
  local MSG_MAX_LENGTH=0

  while read -r TAG TYPE _ _ _ FREE _; do
    local TYPE_PADDED
    local FREE_FMT

    TYPE_PADDED=$(printf "%-10s" "$TYPE")
    FREE_FMT=$(numfmt --to=iec --from-unit=K --format %.2f <<<"$FREE")B
    local ITEM="Type: $TYPE_PADDED Free: $FREE_FMT"

    ((${#ITEM} + 2 > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=$((${#ITEM} + 2))

    MENU+=("$TAG" "$ITEM" "OFF")
  done < <(pvesm status -content "$CONTENT" | awk 'NR>1')

  local OPTION_COUNT=$((${#MENU[@]} / 3))

  # Auto-select if only one option available
  if [[ "$OPTION_COUNT" -eq 1 ]]; then
    echo "${MENU[0]}"
    return 0
  fi

  # Display selection menu
  local STORAGE
  while [[ -z "${STORAGE:+x}" ]]; do
    STORAGE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Storage Pools" --radiolist \
      "Select the storage pool to use for the ${CONTENT_LABEL,,}.\nUse the spacebar to make a selection.\n" \
      16 $((MSG_MAX_LENGTH + 23)) 6 \
      "${MENU[@]}" 3>&1 1>&2 2>&3) || {
      msg_error "Storage selection cancelled."
      exit 202
    }
  done

  echo "$STORAGE"
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

# Get template storage
TEMPLATE_STORAGE=$(select_storage template)
msg_ok "Using ${BL}$TEMPLATE_STORAGE${CL} ${GN}for Template Storage."

# Get container storage
CONTAINER_STORAGE=$(select_storage container)
msg_ok "Using ${BL}$CONTAINER_STORAGE${CL} ${GN}for Container Storage."

# Check free space on selected container storage
STORAGE_FREE=$(pvesm status | awk -v s="$CONTAINER_STORAGE" '$1 == s { print $6 }')
REQUIRED_KB=$((${PCT_DISK_SIZE:-8} * 1024 * 1024))
if [ "$STORAGE_FREE" -lt "$REQUIRED_KB" ]; then
  msg_error "Not enough space on '$CONTAINER_STORAGE'. Needed: ${PCT_DISK_SIZE:-8}G."
  exit 214
fi
# Check Cluster Quorum if in Cluster
if [ -f /etc/pve/corosync.conf ]; then
  msg_info "Checking Proxmox cluster quorum status"
  if ! pvecm status | awk -F':' '/^Quorate/ { exit ($2 ~ /Yes/) ? 0 : 1 }'; then
    printf "\e[?25h"
    msg_error "Cluster is not quorate. Start all nodes or configure quorum device (QDevice)."
    exit 210
  fi
  msg_ok "Cluster is quorate"
fi

# Update LXC template list
TEMPLATE_SEARCH="${PCT_OSTYPE}-${PCT_OSVERSION:-}"

msg_info "Updating LXC Template List"
if ! timeout 15 pveam update >/dev/null 2>&1; then
  TEMPLATE_FALLBACK=$(pveam list "$TEMPLATE_STORAGE" | awk "/$TEMPLATE_SEARCH/ {print \$2}" | sort -t - -k 2 -V | tail -n1)
  if [[ -z "$TEMPLATE_FALLBACK" ]]; then
    msg_error "Failed to update LXC template list and no local template matching '$TEMPLATE_SEARCH' found."
    exit 201
  fi
  msg_info "Skipping template update – using local fallback: $TEMPLATE_FALLBACK"
else
  msg_ok "LXC Template List Updated"
fi

# Get LXC template string
TEMPLATE_SEARCH="${PCT_OSTYPE}-${PCT_OSVERSION:-}"
mapfile -t TEMPLATES < <(pveam available -section system | sed -n "s/.*\($TEMPLATE_SEARCH.*\)/\1/p" | sort -t - -k 2 -V)

if [ ${#TEMPLATES[@]} -eq 0 ]; then
  msg_error "No matching LXC template found for '${TEMPLATE_SEARCH}'. Make sure your host can reach the Proxmox template repository."
  exit 207
fi

TEMPLATE="${TEMPLATES[-1]}"
TEMPLATE_PATH="$(pvesm path $TEMPLATE_STORAGE:vztmpl/$TEMPLATE 2>/dev/null || echo "/var/lib/vz/template/cache/$TEMPLATE")"

# Check if template exists and is valid
if ! pveam list "$TEMPLATE_STORAGE" | grep -q "$TEMPLATE" || ! zstdcat "$TEMPLATE_PATH" | tar -tf - >/dev/null 2>&1; then
  msg_warn "Template $TEMPLATE not found or appears to be corrupted. Re-downloading."

  [[ -f "$TEMPLATE_PATH" ]] && rm -f "$TEMPLATE_PATH"
  for attempt in {1..3}; do
    msg_info "Attempt $attempt: Downloading LXC template..."

    if timeout 120 pveam download "$TEMPLATE_STORAGE" "$TEMPLATE" >/dev/null 2>&1; then
      msg_ok "Template download successful."
      break
    fi

    if [ $attempt -eq 3 ]; then
      msg_error "Failed after 3 attempts. Please check your Proxmox host’s internet access or manually run:\n  pveam download $TEMPLATE_STORAGE $TEMPLATE"
      exit 208
    fi

    sleep $((attempt * 5))
  done
fi

msg_ok "LXC Template '$TEMPLATE' is ready to use."
# Check and fix subuid/subgid
grep -q "root:100000:65536" /etc/subuid || echo "root:100000:65536" >>/etc/subuid
grep -q "root:100000:65536" /etc/subgid || echo "root:100000:65536" >>/etc/subgid

# Combine all options
PCT_OPTIONS=(${PCT_OPTIONS[@]:-${DEFAULT_PCT_OPTIONS[@]}})
[[ " ${PCT_OPTIONS[@]} " =~ " -rootfs " ]] || PCT_OPTIONS+=(-rootfs "$CONTAINER_STORAGE:${PCT_DISK_SIZE:-8}")

# Secure creation of the LXC container with lock and template check
lockfile="/tmp/template.${TEMPLATE}.lock"
exec 9>"$lockfile"
flock -w 60 9 || {
  msg_error "Timeout while waiting for template lock"
  exit 211
}
msg_info "Creating LXC Container"
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

  if ! pct create "$CTID" "${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE}" "${PCT_OPTIONS[@]}" &>/dev/null; then
    msg_error "Container creation failed after re-downloading template."
    exit 200
  fi
fi

if ! pct status "$CTID" &>/dev/null; then
  msg_error "Container not found after pct create – assuming failure."
  exit 210
fi

msg_ok "LXC Container ${BL}$CTID${CL} ${GN}was successfully created."
