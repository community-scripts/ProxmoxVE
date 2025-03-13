#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: rcourtman
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rcourtman/ProxmoxVE

source <(curl -s https://raw.githubusercontent.com/rcourtman/ProxmoxVE/main/misc/build.func)

# Default values
APP="Pulse"
var_tags="monitoring;proxmox;dashboard"
var_cpu="1"
var_ram="1024"
var_disk="6"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

# Update function - Add your specific update logic here
function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/pulse ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  
  # Check for updates
  cd /opt/pulse
  
  # Get current version
  CURRENT_VERSION=$(cat /opt/${NSAPP}/${NSAPP}_version.txt 2>/dev/null || echo "unknown")
  
  # Get the latest version from GitHub API
  msg_info "Checking for updates"
  LATEST_VERSION=$(curl -s https://api.github.com/repos/rcourtman/pulse/releases/latest | grep "tag_name" | cut -d'"' -f4 | sed 's/^v//')
  
  if [[ -z "$LATEST_VERSION" ]]; then
    LATEST_VERSION=$(grep -o '"version": "[^"]*"' package.json | cut -d'"' -f4)
    if [[ -z "$LATEST_VERSION" ]]; then
      msg_error "Failed to determine version information"
      exit
    fi
  fi
  
  # Compare versions and update if needed
  if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
    msg_info "Updating ${APP} from v${CURRENT_VERSION} to v${LATEST_VERSION}"
    
    # Pull latest changes
    $STD git fetch origin
    $STD git reset --hard origin/main
    
    # Install backend dependencies and build
    msg_info "Building backend"
    $STD npm ci
    $STD npm run build
    
    # Install frontend dependencies and build
    msg_info "Building frontend"
    cd /opt/pulse/frontend
    $STD npm ci
    $STD npm run build
    
    # Return to main directory
    cd /opt/pulse
    
    # Save new version
    echo "${LATEST_VERSION}" > /opt/${NSAPP}/${NSAPP}_version.txt
    
    # Restart service
    msg_info "Restarting service"
    $STD systemctl restart ${NSAPP}
    
    msg_ok "Updated ${APP} to v${LATEST_VERSION}"
  else
    msg_ok "No update required. ${APP} is already at v${LATEST_VERSION}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7654${CL}" 