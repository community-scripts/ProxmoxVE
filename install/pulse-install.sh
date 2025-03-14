#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: rcourtman
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rcourtman/pulse

# Import functions and set up environment
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors

# Fix locale issues early to prevent warnings
msg_info "Setting up locale"
$STD apt-get update > /dev/null 2>&1
$STD apt-get install -y locales > /dev/null 2>&1
$STD sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen > /dev/null 2>&1
$STD locale-gen en_US.UTF-8 > /dev/null 2>&1
$STD update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 > /dev/null 2>&1
echo 'export LANG=en_US.UTF-8' >> /etc/profile
echo 'export LC_ALL=en_US.UTF-8' >> /etc/profile
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
msg_ok "Locale configured"

setting_up_container
network_check
update_os

# Application Details
NSAPP=pulse
APP="Pulse"
APPVERSION="1.6.4"  # Current version as of script creation

# Installation Path
APPPATH=/opt/${NSAPP}

# Dependencies
msg_info "Installing dependencies"
$STD apt-get update
$STD apt-get install -y \
  curl \
  git \
  ca-certificates \
  gnupg \
  sudo \
  build-essential
msg_ok "Installed dependencies"

# Install Node.js
msg_info "Installing Node.js"
curl -fsSL https://deb.nodesource.com/setup_20.x | $STD bash -
$STD apt-get install -y nodejs
msg_ok "Installed Node.js $(node -v)"

# Clone repository
msg_info "Setting up application"
mkdir -p ${APPPATH}

# Download and extract release
msg_info "Downloading release v${APPVERSION}"
$STD wget -qO- https://github.com/rcourtman/pulse/releases/download/v${APPVERSION}/pulse-${APPVERSION}.tar.gz | tar xz -C ${APPPATH} --strip-components=1
msg_ok "Release extracted to ${APPPATH}"

# Verify and fix the installation structure 
msg_info "Verifying installation structure"
ls -la ${APPPATH}
# Ensure dist directory exists
if [ ! -d ${APPPATH}/dist ]; then
  mkdir -p ${APPPATH}/dist
fi
# Ensure public directory exists
if [ ! -d ${APPPATH}/dist/public ]; then
  mkdir -p ${APPPATH}/dist/public
fi

# If frontend files are in a different location, copy them to the expected location
if [ -d ${APPPATH}/frontend/dist ] && [ ! -d ${APPPATH}/dist/public ]; then
  cp -r ${APPPATH}/frontend/dist ${APPPATH}/dist/public
fi
if [ -d ${APPPATH}/public ] && [ ! -d ${APPPATH}/dist/public ]; then
  cp -r ${APPPATH}/public ${APPPATH}/dist/
fi

# Create symlink to help find frontend files (common solution)
if [ -d ${APPPATH}/frontend/dist ] && [ ! -L ${APPPATH}/dist/public ]; then
  ln -s ${APPPATH}/frontend/dist ${APPPATH}/dist/public
fi

# Fallback: If frontend files are still missing after our fixes, build them
if [ ! -d ${APPPATH}/dist/public ] || [ -z "$(ls -A ${APPPATH}/dist/public 2>/dev/null)" ]; then
  msg_info "Frontend files not found in the pre-built package. Building them now..."
  if [ -d ${APPPATH}/frontend ]; then
    cd ${APPPATH}/frontend
    $STD npm ci
    $STD npm run build
    if [ -d ${APPPATH}/frontend/dist ]; then
      mkdir -p ${APPPATH}/dist/public
      cp -r ${APPPATH}/frontend/dist/* ${APPPATH}/dist/public/
    fi
  fi
fi

msg_ok "Installation structure verified"

# Set up environment file
msg_info "Setting up environment"
cat > ${APPPATH}/.env.example << 'EOF'
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
EOF

cp ${APPPATH}/.env.example ${APPPATH}/.env
msg_ok "Environment configuration created"

# Create service file
msg_info "Setting up systemd services"
cat <<EOF >/etc/systemd/system/${NSAPP}.service
[Unit]
Description=Pulse for Proxmox Monitoring
After=network.target
After=${NSAPP}-mock.service

[Service]
Type=simple
User=root
WorkingDirectory=${APPPATH}
Environment=NODE_ENV=production
Environment=MOCK_SERVER_PORT=7656
ExecStart=/usr/bin/node ${APPPATH}/dist/server.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create a separate service for the mock data server
msg_info "Setting up mock data server service"
cat <<EOF >/etc/systemd/system/${NSAPP}-mock.service
[Unit]
Description=Pulse Mock Data Server
After=network.target
Before=${NSAPP}.service

[Service]
Type=simple
User=root
WorkingDirectory=${APPPATH}
Environment=NODE_ENV=production
Environment=MOCK_SERVER_PORT=7656
ExecStart=/usr/bin/npx ts-node ${APPPATH}/src/mock/run-server.ts
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the mock service first
msg_info "Enabling services"
$STD systemctl enable ${NSAPP}-mock > /dev/null 2>&1
$STD systemctl start ${NSAPP}-mock > /dev/null 2>&1

# Enable and start the main service
$STD systemctl enable ${NSAPP} > /dev/null 2>&1
$STD systemctl start ${NSAPP} > /dev/null 2>&1
msg_ok "Services started"

# Set proper file permissions
msg_info "Setting file permissions"
chown -R root:root ${APPPATH}
chmod -R 755 ${APPPATH}
chmod 600 ${APPPATH}/.env
chmod 644 ${APPPATH}/.env.example
msg_ok "File permissions set"

# Add the motd (Message of the Day) and SSH customization
motd_ssh
customize

# Final steps
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned up"

# Create update script for easy updates
echo "bash -c \"\$(wget -qLO - https://github.com/rcourtman/ProxmoxVE/raw/main/ct/${NSAPP}.sh)\"" >/usr/bin/update
chmod +x /usr/bin/update

# Message to display when complete
msg_ok "${APP} installation complete"

# Final message with configuration instructions
cat <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${APP} installation complete.

${APP} is running with demo data.
Access it now at: http://${IP}:7654

To connect to your real Proxmox server:
1. Edit the .env file:
   nano /opt/${NSAPP}/.env
    
2. Change these settings:
   - Set USE_MOCK_DATA=false
   - Set MOCK_DATA_ENABLED=false
   - Configure your Proxmox credentials:
     PROXMOX_NODE_1_NAME=Your Node Name
     PROXMOX_NODE_1_HOST=https://your-proxmox-ip:8006
     PROXMOX_NODE_1_TOKEN_ID=root@pam!pulse
     PROXMOX_NODE_1_TOKEN_SECRET=your-token-secret

3. Restart Pulse:
   systemctl restart ${NSAPP}
 
To update ${APP} in the future, run: update
 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF 