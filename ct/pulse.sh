#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: rcourtman
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rcourtman/pulse

# NOTE: This script was significantly updated on March 13, 2025.
# If you're seeing errors about missing files or wget commands,
# you are using an outdated version. Please use the latest version:
# bash -c "$(curl -s https://raw.githubusercontent.com/rcourtman/ProxmoxVE/main/ct/pulse.sh)"
# Current version uses direct commands and doesn't rely on external installation scripts.

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
PULSE_VERSION="1.6.4"  # Current version to install

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

# Set up the locale environment in the container early
function setup_locale_environment() {
  # Install locales package if needed
  pct exec ${CTID} -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y locales > /dev/null 2>&1"
  
  # Configure locales silently
  pct exec ${CTID} -- bash -c "sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen"
  pct exec ${CTID} -- bash -c "locale-gen > /dev/null 2>&1"
  
  # Set environment variables directly in container
  pct exec ${CTID} -- bash -c "echo 'LANG=en_US.UTF-8' > /etc/default/locale"
  pct exec ${CTID} -- bash -c "echo 'LC_ALL=en_US.UTF-8' >> /etc/default/locale"
  pct exec ${CTID} -- bash -c "echo 'export LANG=en_US.UTF-8' >> /etc/profile"
  pct exec ${CTID} -- bash -c "echo 'export LC_ALL=en_US.UTF-8' >> /etc/profile"
  
  # Also set directly in current environment
  pct exec ${CTID} -- bash -c "export LANG=en_US.UTF-8 && export LC_ALL=en_US.UTF-8"
}

start
build_container
description

# Set up locale immediately after container is created
setup_locale_environment

# Simplify the installation process with direct commands
msg_info "Setting up Pulse installation in the container"

# Install core dependencies directly
pct exec ${CTID} -- bash -c "apt-get update > /dev/null 2>&1"
pct exec ${CTID} -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y curl git ca-certificates gnupg sudo build-essential > /dev/null 2>&1"
msg_ok "Core dependencies installed"

# Installing Node.js
msg_info "Installing Node.js"
pct exec ${CTID} -- bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1"
pct exec ${CTID} -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs > /dev/null 2>&1"
msg_ok "Node.js installed"

# Create application directory
msg_info "Creating application directory"
pct exec ${CTID} -- bash -c "mkdir -p /opt/pulse"
msg_ok "Application directory created"

# Download and extract pre-built release instead of cloning and building
msg_info "Downloading Pulse v${PULSE_VERSION} release"
pct exec ${CTID} -- bash -c "wget -qO- https://github.com/rcourtman/pulse/releases/download/v${PULSE_VERSION}/pulse-${PULSE_VERSION}.tar.gz | tar xz -C /opt/pulse --strip-components=1 > /dev/null 2>&1"
msg_ok "Release downloaded and extracted"

# Verify the extracted files and structure
msg_info "Verifying installation structure"
pct exec ${CTID} -- bash -c "ls -la /opt/pulse"
pct exec ${CTID} -- bash -c "if [ ! -d /opt/pulse/dist ]; then mkdir -p /opt/pulse/dist; fi"
pct exec ${CTID} -- bash -c "if [ ! -d /opt/pulse/dist/public ]; then mkdir -p /opt/pulse/dist/public; fi"

# If frontend files are in a different location, copy them to the expected location
pct exec ${CTID} -- bash -c "if [ -d /opt/pulse/frontend/dist ] && [ ! -d /opt/pulse/dist/public ]; then cp -r /opt/pulse/frontend/dist /opt/pulse/dist/public; fi"
pct exec ${CTID} -- bash -c "if [ -d /opt/pulse/public ] && [ ! -d /opt/pulse/dist/public ]; then cp -r /opt/pulse/public /opt/pulse/dist/; fi"

# Create symlink to help find frontend files (common solution)
pct exec ${CTID} -- bash -c "if [ -d /opt/pulse/frontend/dist ] && [ ! -L /opt/pulse/dist/public ]; then ln -s /opt/pulse/frontend/dist /opt/pulse/dist/public; fi"

# Check the directory structure after our fixes
pct exec ${CTID} -- bash -c "echo 'Content of /opt/pulse/dist:'; ls -la /opt/pulse/dist || echo 'dist directory does not exist'"
pct exec ${CTID} -- bash -c "echo 'Content of /opt/pulse/dist/public (if exists):'; ls -la /opt/pulse/dist/public 2>/dev/null || echo 'public directory does not exist'"
pct exec ${CTID} -- bash -c "echo 'Checking for frontend source:'; ls -la /opt/pulse/frontend 2>/dev/null || echo 'frontend directory does not exist'"

# Fallback: If frontend files are still missing after our fixes, build them
pct exec ${CTID} -- bash -c "if [ ! -d /opt/pulse/dist/public ] || [ -z \"\$(ls -A /opt/pulse/dist/public 2>/dev/null)\" ]; then
  echo 'Frontend files not found in the pre-built package. Building them now...'
  
  # First check if the frontend directory exists
  if [ -d /opt/pulse/frontend ]; then
    echo 'Found frontend directory, building from source...'
    cd /opt/pulse/frontend
    
    # Install dependencies and build
    npm ci
    npm run build
    
    # Check if build was successful
    if [ -d /opt/pulse/frontend/dist ]; then
      echo 'Frontend built successfully, copying files...'
      mkdir -p /opt/pulse/dist/public
      cp -r /opt/pulse/frontend/dist/* /opt/pulse/dist/public/
      echo 'Frontend copied to /opt/pulse/dist/public'
      ls -la /opt/pulse/dist/public
    else
      echo 'Frontend build failed, no dist directory created'
      exit 1
    fi
  else
    # If frontend directory doesn't exist, clone the repo and build
    echo 'Frontend directory not found, cloning repository...'
    cd /opt/pulse
    git clone https://github.com/rcourtman/pulse.git /tmp/pulse-build
    
    if [ -d /tmp/pulse-build/frontend ]; then
      echo 'Cloned repository, building frontend...'
      cd /tmp/pulse-build/frontend
      npm ci
      npm run build
      
      if [ -d /tmp/pulse-build/frontend/dist ]; then
        echo 'Frontend built successfully, copying files...'
        mkdir -p /opt/pulse/dist/public
        cp -r /tmp/pulse-build/frontend/dist/* /opt/pulse/dist/public/
        echo 'Frontend copied to /opt/pulse/dist/public'
        ls -la /opt/pulse/dist/public
      else
        echo 'Frontend build failed, no dist directory created'
        exit 1
      fi
      
      # Clean up
      rm -rf /tmp/pulse-build
    else
      echo 'Failed to clone repository or find frontend directory'
      exit 1
    fi
  fi
else
  echo 'Frontend files found, no need to build'
fi"

msg_ok "Installation structure verified"

# Set up environment configuration
msg_info "Setting up environment configuration"
pct exec ${CTID} -- bash -c "cat > /opt/pulse/.env.example << 'EOFENV'
# Proxmox Node Configuration
# You can add up to 10 nodes by incrementing the number in PROXMOX_NODE_X_* variables

# Node 1 (Required)
PROXMOX_NODE_1_NAME=pve
PROXMOX_NODE_1_HOST=https://your-proxmox-ip:8006
PROXMOX_NODE_1_TOKEN_ID=root@pam!pulse
PROXMOX_NODE_1_TOKEN_SECRET=your-token-secret

# Node 2 (Optional)
# PROXMOX_NODE_2_NAME=pve2
# PROXMOX_NODE_2_HOST=https://your-second-proxmox-ip:8006
# PROXMOX_NODE_2_TOKEN_ID=root@pam!pulse
# PROXMOX_NODE_2_TOKEN_SECRET=your-token-secret

# API Settings
IGNORE_SSL_ERRORS=true
NODE_TLS_REJECT_UNAUTHORIZED=0
API_RATE_LIMIT_MS=2000
API_TIMEOUT_MS=90000
API_RETRY_DELAY_MS=10000

# Mock Data Settings (enabled by default for initial experience)
# Set to 'false' when ready to connect to real Proxmox server
USE_MOCK_DATA=true
MOCK_DATA_ENABLED=true
MOCK_SERVER_PORT=7656

# Mock Cluster Settings
MOCK_CLUSTER_ENABLED=true
MOCK_CLUSTER_NAME=mock-cluster
EOFENV"

pct exec ${CTID} -- bash -c "cp /opt/pulse/.env.example /opt/pulse/.env"
msg_ok "Environment configuration created"

# Create service file
msg_info "Creating service files"
pct exec ${CTID} -- bash -c "cat > /etc/systemd/system/pulse.service << 'EOFSVC'
[Unit]
Description=Pulse for Proxmox Monitoring
After=network.target
After=pulse-mock.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/pulse
Environment=NODE_ENV=production
Environment=MOCK_SERVER_PORT=7656
ExecStart=/usr/bin/node /opt/pulse/dist/server.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSVC"
msg_ok "Main service file created"

# Create mock data server service
msg_info "Creating mock server service file"
pct exec ${CTID} -- bash -c "cat > /etc/systemd/system/pulse-mock.service << 'EOFSVC'
[Unit]
Description=Pulse Mock Data Server
After=network.target
Before=pulse.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/pulse
Environment=NODE_ENV=production
Environment=MOCK_SERVER_PORT=7656
ExecStart=/usr/bin/npx ts-node /opt/pulse/src/mock/run-server.ts
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSVC"
msg_ok "Mock server service file created"

# Set file permissions
msg_info "Setting file permissions"
pct exec ${CTID} -- bash -c "chown -R root:root /opt/pulse && chmod -R 755 /opt/pulse && chmod 600 /opt/pulse/.env && chmod 644 /opt/pulse/.env.example"
msg_ok "File permissions set"

# Save version info
pct exec ${CTID} -- bash -c "echo '1.6.3' > /opt/pulse/pulse_version.txt"

# Create update script
msg_info "Creating update utility"
pct exec ${CTID} -- bash -c "echo 'bash -c \"\$(wget -qLO - https://github.com/rcourtman/ProxmoxVE/raw/main/ct/pulse.sh)\"' > /usr/bin/update && chmod +x /usr/bin/update"
msg_ok "Update utility created"

# Enable and start services
msg_info "Enabling and starting services"
pct exec ${CTID} -- bash -c "systemctl enable pulse-mock > /dev/null 2>&1 && systemctl start pulse-mock > /dev/null 2>&1"
pct exec ${CTID} -- bash -c "systemctl enable pulse > /dev/null 2>&1 && systemctl start pulse > /dev/null 2>&1"
msg_ok "Pulse services started"

# Complete the installation message
msg_ok "Pulse installation complete"

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
echo -e "${GN}${APP} setup has been successfully initialized.${CL}"
echo -e "${YW}Access it using the following URL:${CL}"
echo -e "    ${BGN}http://${IP}:7654${CL}" 

# Provide instructions for demo mode and real configuration
echo -e "\n${YW}${APP} is running with demo data.${CL}"
echo -e "    You can explore the interface immediately."

echo -e "\n${YW}To connect to your actual Proxmox server:${CL}"
echo -e "    1. Execute the following on the host:"
echo -e "       pct exec ${CTID} -- bash -c \"nano /opt/pulse/.env\""
echo -e "    2. Change these settings in the .env file:"
echo -e "       - Set USE_MOCK_DATA=false"
echo -e "       - Set MOCK_DATA_ENABLED=false"
echo -e "       - Configure your Proxmox credentials"
echo -e "    3. Restart the service:"
echo -e "       pct exec ${CTID} -- bash -c \"systemctl restart pulse\""

# Final instructions
echo -e "\n${YW}To update ${APP} in the future:${CL}"
echo -e "    pct exec ${CTID} -- bash -c \"update\""

# Force a flush of output
printf "\n" 