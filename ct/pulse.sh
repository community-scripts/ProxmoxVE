#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: rcourtman
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rcourtman/pulse

source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Default values
APP="Pulse"
NSAPP="pulse"  # This must match the install script filename (pulse-install.sh) without the "-install.sh"
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
  if [[ ! -d /opt/${NSAPP} ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  
  # Check for updates
  cd /opt/${NSAPP}
  
  # Get current version
  if [[ -f /opt/${NSAPP}/${NSAPP}_version.txt ]]; then
    CURRENT_VERSION=$(cat /opt/${NSAPP}/${NSAPP}_version.txt)
  else
    CURRENT_VERSION="unknown"
  fi
  
  # Get the latest version from GitHub API
  msg_info "Checking for updates"
  LATEST_VERSION=$(curl -s https://api.github.com/repos/rcourtman/pulse/releases/latest | grep "tag_name" | cut -d'"' -f4 | sed 's/^v//')
  
  if [[ -z "$LATEST_VERSION" ]]; then
    # If unable to get version from releases, check package.json
    LATEST_VERSION=$(grep -o '"version": "[^"]*"' package.json | cut -d'"' -f4)
    if [[ -z "$LATEST_VERSION" ]]; then
      msg_error "Failed to determine version information"
      exit
    fi
  fi
  
  # Compare versions and update if needed
  if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
    msg_info "Updating ${APP} from v${CURRENT_VERSION} to v${LATEST_VERSION}"
    
    # Backup .env file first
    if [[ -f /opt/${NSAPP}/.env ]]; then
      cp /opt/${NSAPP}/.env /opt/${NSAPP}/.env.backup
      msg_ok "Backed up existing configuration"
    fi
    
    # Backup .env.example file if it exists
    if [[ -f /opt/${NSAPP}/.env.example ]]; then
      cp /opt/${NSAPP}/.env.example /opt/${NSAPP}/.env.example.backup
    fi
    
    # Pull latest changes
    $STD git fetch origin
    $STD git reset --hard origin/main
    
    # Restore .env if it was backed up
    if [[ -f /opt/${NSAPP}/.env.backup ]]; then
      cp /opt/${NSAPP}/.env.backup /opt/${NSAPP}/.env
      msg_ok "Restored existing configuration"
    fi
    
    # Restore .env.example if it was backed up
    if [[ -f /opt/${NSAPP}/.env.example.backup ]]; then
      cp /opt/${NSAPP}/.env.example.backup /opt/${NSAPP}/.env.example
    fi
    
    # Install backend dependencies and build
    msg_info "Building backend"
    $STD npm ci
    $STD npm run build
    
    # Install frontend dependencies and build
    msg_info "Building frontend"
    cd /opt/${NSAPP}/frontend
    $STD npm ci
    $STD npm run build
    
    # Return to main directory
    cd /opt/${NSAPP}
    
    # Set permissions again
    chown -R root:root ${APPPATH}
    chmod -R 755 ${APPPATH}
    chmod 600 ${APPPATH}/.env
    
    # Save new version
    echo "${LATEST_VERSION}" > /opt/${NSAPP}/${NSAPP}_version.txt
    
    # Restart service
    msg_info "Restarting service"
    $STD systemctl restart ${NSAPP}
    
    msg_ok "Updated ${APP} to v${LATEST_VERSION}"
    
    # Show access information
    IP=$(hostname -I | awk '{print $1}')
    echo -e "${INFO}${YW} Access it using the following URL:${CL}"
    echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7654${CL}"
  else
    msg_ok "No update required. ${APP} is already at v${LATEST_VERSION}"
  fi
  exit
}

start
build_container
description

# Get the IP address of the container
if [ -z "${IP}" ]; then
  IP=$(pct exec ${CTID} ip a s dev eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "CONTAINER_IP")
  if [[ "${IP}" == "CONTAINER_IP" ]]; then
    # Fallback: Get the IP from the container configuration
    IP=$(pct config ${CTID} | grep -E 'net0' | grep -oP '(?<=ip=)\d+(\.\d+){3}')
  fi
fi

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7654${CL}" 

# Provide instructions for configuration
echo -e "\n${INFO}${YW}Configuration Required:${CL}"
echo -e "${TAB}${GATEWAY}${BL}1. Execute the following on the host: ${CL}"
echo -e "${TAB}${GATEWAY}${GN}   pct exec ${CTID} -- bash -c \"nano /opt/pulse/.env\"${CL}"
echo -e "${TAB}${GATEWAY}${BL}2. Set the required Proxmox credentials in the .env file${CL}"
echo -e "${TAB}${GATEWAY}${BL}   (Reference .env.example for all available options)${CL}"
echo -e "${TAB}${GATEWAY}${BL}3. Start the service:${CL}"
echo -e "${TAB}${GATEWAY}${GN}   pct exec ${CTID} -- bash -c \"systemctl start pulse\"${CL}"

# Final instructions
echo -e "\n${INFO}${YW}To update ${APP} in the future:${CL}"
echo -e "${TAB}${GATEWAY}${GN}   pct exec ${CTID} -- bash -c \"update\"${CL}" 