#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: rcourtman
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rcourtman/pulse

# Initialize spinner variable for safety
export SPINNER_PID=""

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
      
      # Save mock data settings
      USE_MOCK_DATA=$(grep "USE_MOCK_DATA" /opt/${NSAPP}/.env | cut -d= -f2)
      MOCK_DATA_ENABLED=$(grep "MOCK_DATA_ENABLED" /opt/${NSAPP}/.env | cut -d= -f2)
      MOCK_CLUSTER_ENABLED=$(grep "MOCK_CLUSTER_ENABLED" /opt/${NSAPP}/.env | cut -d= -f2 || echo "true")
      MOCK_CLUSTER_NAME=$(grep "MOCK_CLUSTER_NAME" /opt/${NSAPP}/.env | cut -d= -f2 || echo "Demo Cluster")
      
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
      
      # Ensure mock data settings are preserved
      if [[ -n "$USE_MOCK_DATA" ]]; then
        sed -i "s/USE_MOCK_DATA=.*/USE_MOCK_DATA=$USE_MOCK_DATA/" /opt/${NSAPP}/.env
        sed -i "s/MOCK_DATA_ENABLED=.*/MOCK_DATA_ENABLED=$MOCK_DATA_ENABLED/" /opt/${NSAPP}/.env
        
        # Add or update mock cluster settings
        if grep -q "MOCK_CLUSTER_ENABLED" /opt/${NSAPP}/.env; then
          sed -i "s/MOCK_CLUSTER_ENABLED=.*/MOCK_CLUSTER_ENABLED=$MOCK_CLUSTER_ENABLED/" /opt/${NSAPP}/.env
        else
          echo "MOCK_CLUSTER_ENABLED=$MOCK_CLUSTER_ENABLED" >> /opt/${NSAPP}/.env
        fi
        
        if grep -q "MOCK_CLUSTER_NAME" /opt/${NSAPP}/.env; then
          sed -i "s/MOCK_CLUSTER_NAME=.*/MOCK_CLUSTER_NAME=$MOCK_CLUSTER_NAME/" /opt/${NSAPP}/.env
        else
          echo "MOCK_CLUSTER_NAME=$MOCK_CLUSTER_NAME" >> /opt/${NSAPP}/.env
        fi
      fi
      
      msg_ok "Restored existing configuration"
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

# Create a simple wrapper script to download and execute the installation
msg_info "Preparing installation in the container"
cat > /tmp/install-wrapper.sh << 'EOF'
#!/bin/bash

# Download the install.func
wget -qO /tmp/install.func https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func

# Download the installation script
wget -qO /tmp/pulse-install.sh https://raw.githubusercontent.com/rcourtman/ProxmoxVE/main/install/pulse-install.sh

# Make it executable
chmod +x /tmp/pulse-install.sh

# Execute the script with the functions file
export FUNCTIONS_FILE_PATH="$(cat /tmp/install.func)"
bash /tmp/pulse-install.sh

# Cleanup
rm /tmp/install.func
rm /tmp/pulse-install.sh
EOF

# Make the wrapper script executable
chmod +x /tmp/install-wrapper.sh

# Copy the script to the container
pct push ${CTID} /tmp/install-wrapper.sh /tmp/install-wrapper.sh

# Execute the wrapper script in the container
pct exec ${CTID} -- bash -c "chmod +x /tmp/install-wrapper.sh && /tmp/install-wrapper.sh"
msg_ok "Installation complete"

# Configure locale in the container to support emojis and UTF-8
pct exec ${CTID} -- bash -c "apt-get update > /dev/null 2>&1 && apt-get install -y locales > /dev/null 2>&1"
pct exec ${CTID} -- bash -c "locale-gen en_US.UTF-8 > /dev/null 2>&1"
pct exec ${CTID} -- bash -c "update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 > /dev/null 2>&1"

# Get the IP address of the container and ensure we have a valid IP
if [ -z "${IP}" ]; then
  # Try multiple methods to get the IP address
  IP=$(pct exec ${CTID} ip a s dev eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "")
  if [ -z "${IP}" ]; then
    IP=$(pct config ${CTID} | grep -E 'net0' | grep -oP '(?<=ip=)\d+(\.\d+){3}' || echo "")
    if [ -z "${IP}" ]; then
      # Last resort - get IP after a brief delay
      sleep 5
      IP=$(pct exec ${CTID} hostname -I | awk '{print $1}' || echo "CONTAINER_IP")
    fi
  fi
fi

# Ensure final messages are displayed properly with proper formatting
printf "\n"
echo -e "${BFR}${CM}${GN}Completed Successfully!${CL}\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7654${CL}" 

# Provide instructions for demo mode and real configuration
echo -e "\n${INFO}${YW}Pulse is ALREADY RUNNING with demo data!${CL}"
echo -e "${TAB}${GATEWAY}${BL}You can explore the interface immediately.${CL}"

echo -e "\n${INFO}${YW}To connect to your actual Proxmox server:${CL}"
echo -e "${TAB}${GATEWAY}${BL}1. Execute the following on the host: ${CL}"
echo -e "${TAB}${GATEWAY}${GN}   pct exec ${CTID} -- bash -c \"nano /opt/pulse/.env\"${CL}"
echo -e "${TAB}${GATEWAY}${BL}2. Change these settings in the .env file:${CL}"
echo -e "${TAB}${GATEWAY}${BL}   - Set USE_MOCK_DATA=false${CL}"
echo -e "${TAB}${GATEWAY}${BL}   - Set MOCK_DATA_ENABLED=false${CL}"
echo -e "${TAB}${GATEWAY}${BL}   - Configure your Proxmox credentials${CL}"
echo -e "${TAB}${GATEWAY}${BL}3. Restart the service:${CL}"
echo -e "${TAB}${GATEWAY}${GN}   pct exec ${CTID} -- bash -c \"systemctl restart pulse\"${CL}"

# Final instructions
echo -e "\n${INFO}${YW}To update ${APP} in the future:${CL}"
echo -e "${TAB}${GATEWAY}${GN}   pct exec ${CTID} -- bash -c \"update\"${CL}"

# Force a flush of output
printf "\n" 