#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: Heretek-AI
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://images.linuxcontainers.org/

APP="Kali"
var_tags="${var_tags:-security;pentest;kali;linux}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
var_os="${var_os:-kali}"
var_version="${var_version:-current}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /etc/os-release ]] || ! grep -qi "kali" /etc/os-release 2>/dev/null; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating ${APP} LXC Container"
  $STD apt-get update
  $STD apt-get upgrade -y
  msg_ok "Updated ${APP} LXC Container"
  exit
}

# Download Kali template from images.linuxcontainers.org
# This runs BEFORE build_container to ensure template is available
function fetch_kali_template() {
  local STORAGE="${var_template_storage:-local}"
  local TEMPLATE_DIR
  
  # Get template directory based on storage
  if [[ "$STORAGE" == "local" ]]; then
    TEMPLATE_DIR="/var/lib/vz/template/cache"
  else
    # Get path from Proxmox storage config
    TEMPLATE_DIR=$(grep -E "^[^:]+: ${STORAGE}$" /etc/pve/storage.cfg -A10 2>/dev/null | grep "path" | awk '{print $2}')
    [[ -z "$TEMPLATE_DIR" ]] && TEMPLATE_DIR="/var/lib/vz"
    TEMPLATE_DIR="${TEMPLATE_DIR}/template/cache"
  fi
  
  # Create directory if it doesn't exist
  mkdir -p "${TEMPLATE_DIR}"
  
  # Kali template URL from images.linuxcontainers.org
  # Structure: https://images.linuxcontainers.org/images/kali/current/amd64/default/YYYYMMDD_HH:MM/rootfs.tar.xz
  local KALI_BASE_URL="https://images.linuxcontainers.org/images/kali/current/amd64/default/"
  
  msg_info "Fetching latest Kali template from images.linuxcontainers.org"
  
  # Get the directory listing to find the latest date folder
  local PAGE_CONTENT
  PAGE_CONTENT=$(curl -fsSL "${KALI_BASE_URL}" 2>/dev/null)
  
  if [[ -z "$PAGE_CONTENT" ]]; then
    msg_error "Failed to fetch Kali template listing from ${KALI_BASE_URL}"
    msg_error "Please check your network connection and try again"
    exit 225
  fi
  
  # Parse the page to find the latest date directory
  # The page format is: [YYYYMMDD_HH:MM/](url) with date
  # We need to extract the directory names like 20260311_17:14
  
  local LATEST_DIR
  
  # Simple approach: use grep to find all date patterns and sort them
  # Pattern: 8 digits, underscore, 2 digits, colon, 2 digits
  LATEST_DIR=$(echo "$PAGE_CONTENT" | grep -o '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9]:[0-9][0-9]' | sort -r | head -n 1)
  
  if [[ -z "$LATEST_DIR" ]]; then
    msg_error "Could not find Kali template directory in the listing"
    msg_error "Please visit ${KALI_BASE_URL} manually"
    exit 225
  fi
  
  # Remove trailing slash if present
  LATEST_DIR="${LATEST_DIR%/}"
  
  msg_info "Found latest Kali template directory: ${LATEST_DIR}"
  
  # Construct the full URL to rootfs.tar.xz
  local TEMPLATE_URL="${KALI_BASE_URL}${LATEST_DIR}/rootfs.tar.xz"
  
  # Create a friendly template name for Proxmox (replace : with - for compatibility)
  local DATE_PART="${LATEST_DIR//:/-}"
  local TEMPLATE_NAME="kali-current-amd64-default-${DATE_PART}.tar.xz"
  local TEMPLATE_PATH="${TEMPLATE_DIR}/${TEMPLATE_NAME}"
  
  # Check if template already exists and is valid
  # Kali minimal templates can be as small as 50MB when compressed
  if [[ -f "$TEMPLATE_PATH" ]]; then
    local FILE_SIZE
    FILE_SIZE=$(stat -c%s "$TEMPLATE_PATH" 2>/dev/null || echo 0)
    if [[ $FILE_SIZE -gt 50000000 ]]; then
      msg_ok "Kali template already downloaded: ${TEMPLATE_NAME}"
      echo "${TEMPLATE_NAME}"
      return 0
    else
      msg_warn "Existing template file too small (${FILE_SIZE} bytes), re-downloading"
      rm -f "$TEMPLATE_PATH"
    fi
  fi
  
  msg_info "Downloading Kali template: ${TEMPLATE_NAME}"
  msg_info "URL: ${TEMPLATE_URL}"
  msg_info "Target: ${TEMPLATE_PATH}"
  
  # Download with progress
  local DOWNLOAD_STATUS=0
  if command -v wget &>/dev/null; then
    if wget --progress=bar:force -O "${TEMPLATE_PATH}" "${TEMPLATE_URL}" 2>&1; then
      DOWNLOAD_STATUS=1
    fi
  elif command -v curl &>/dev/null; then
    if curl -L --progress-bar -o "${TEMPLATE_PATH}" "${TEMPLATE_URL}" 2>&1; then
      DOWNLOAD_STATUS=1
    fi
  else
    msg_error "Neither wget nor curl available for download"
    exit 222
  fi
  
  if [[ $DOWNLOAD_STATUS -eq 0 ]]; then
    msg_error "Failed to download Kali template"
    rm -f "${TEMPLATE_PATH}"
    exit 222
  fi
  
  # Verify download
  # Kali minimal templates can be as small as 50MB when compressed
  local DOWNLOADED_SIZE
  DOWNLOADED_SIZE=$(stat -c%s "${TEMPLATE_PATH}" 2>/dev/null || echo 0)
  if [[ $DOWNLOADED_SIZE -lt 50000000 ]]; then
    msg_error "Downloaded template is too small (${DOWNLOADED_SIZE} bytes)"
    msg_error "Expected at least 50MB for a valid Kali template"
    rm -f "${TEMPLATE_PATH}"
    exit 222
  fi
  
  msg_ok "Successfully downloaded Kali template: ${TEMPLATE_NAME} ($(numfmt --to=iec --from-unit=1024 --format %.1f "${DOWNLOADED_SIZE}" 2>/dev/null || echo "${DOWNLOADED_SIZE}")B)"
  
  # Return the template name for use by build_container
  echo "${TEMPLATE_NAME}"
}

# Build function override to handle Kali template download
# This runs before build_container to set up the template
function build_kali_container() {
  # Download template first
  local KALI_TEMPLATE
  KALI_TEMPLATE=$(fetch_kali_template)
  
  # Set template for build_container
  export TEMPLATE="${KALI_TEMPLATE}"
  export TEMPLATE_SOURCE="local"
  
  # Now call the standard build_container which sets up PCT_OPTIONS
  # and calls create_lxc_container internally
  build_container
}

start
build_kali_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} LXC has been successfully created!${CL}"
echo -e "${INFO}${YW} Access it using: ${BGN}pct enter ${CTID}${CL}"
echo -e "${INFO}${YW} Or SSH: ${BGN}ssh root@${IP}${CL}"
