#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: rcourtman
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rcourtman/ProxmoxVE

# Import functions and set up environment
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Application Details
NSAPP=pulse
APP="Pulse"
APPVERSION="1.6.3"  # Current version as of script creation

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

# Install Node.js
msg_info "Installing Node.js"
curl -fsSL https://deb.nodesource.com/setup_20.x | $STD bash -
$STD apt-get install -y nodejs
msg_ok "Installed Node.js $(node -v)"

# Create application directories
msg_info "Creating application directories"
mkdir -p ${APPPATH}
cd ${APPPATH}
msg_ok "Created application directories"

# Clone and setup Pulse
msg_info "Downloading Pulse from GitHub"
$STD git clone https://github.com/rcourtman/pulse.git .
msg_ok "Downloaded Pulse"

# Save version information
echo "${APPVERSION}" > "${APPPATH}/${NSAPP}_version.txt"

# Configure Pulse
msg_info "Configuring Pulse"
cat <<EOF >${APPPATH}/.env
# Pulse Environment Configuration
# Required Proxmox Configuration
PROXMOX_NODE_1_NAME=Proxmox Node 1
PROXMOX_NODE_1_HOST=https://your-proxmox-host:8006
PROXMOX_NODE_1_TOKEN_ID=root@pam!pulse
PROXMOX_NODE_1_TOKEN_SECRET=your-token-secret

# Basic Configuration
NODE_ENV=production
LOG_LEVEL=info
PORT=7654

# Performance settings
METRICS_HISTORY_MINUTES=30
NODE_POLLING_INTERVAL_MS=15000
EVENT_POLLING_INTERVAL_MS=5000
API_RATE_LIMIT_MS=2000
API_TIMEOUT_MS=90000
API_RETRY_DELAY_MS=10000

# Disable mock data in production
USE_MOCK_DATA=false
MOCK_DATA_ENABLED=false

# SSL Configuration (uncomment if needed)
# IGNORE_SSL_ERRORS=true
# NODE_TLS_REJECT_UNAUTHORIZED=0
EOF

cat <<EOF >${APPPATH}/README.txt
====== Pulse for Proxmox VE ======

1. Edit the .env file with your Proxmox credentials:
   nano /opt/pulse/.env

2. Required Proxmox settings:
   - PROXMOX_NODE_1_NAME=Your Node Name
   - PROXMOX_NODE_1_HOST=https://your-proxmox-ip:8006
   - PROXMOX_NODE_1_TOKEN_ID=root@pam!pulse
   - PROXMOX_NODE_1_TOKEN_SECRET=your-token-secret

3. Restart the Pulse service:
   systemctl restart pulse

====== Important Notes ======

- Pulse is accessible at: http://${IP}:7654
- Documentation: https://github.com/rcourtman/pulse
- For issues or support: https://github.com/rcourtman/pulse/issues
EOF
msg_ok "Configured Pulse"

# Build the application
msg_info "Installing dependencies and building application"
$STD npm ci
$STD npm run build

# Build the frontend
cd ${APPPATH}/frontend
$STD npm ci
$STD npm run build
cd ${APPPATH}
msg_ok "Built application"

# Create service file
msg_info "Setting up systemd service"
cat <<EOF >/etc/systemd/system/${NSAPP}.service
[Unit]
Description=Pulse for Proxmox Monitoring
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${APPPATH}
Environment=NODE_ENV=production
ExecStart=/usr/bin/node ${APPPATH}/dist/server.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable the service but don't start (needs configuration)
$STD systemctl enable ${NSAPP}
msg_ok "Setup systemd service"

# Final steps
msg_info "Cleaning up"
apt-get -y autoremove
apt-get -y autoclean
msg_ok "Cleaned up"

# Message to display when complete
msg_info "Completing ${APP} installation"
echo "Application Name: ${APP}" > ${APPPATH}/${NSAPP}.txt
echo "Application Version: ${APPVERSION}" >> ${APPPATH}/${NSAPP}.txt
echo "Access URL: http://${IP}:7654 (after configuration)" >> ${APPPATH}/${NSAPP}.txt
msg_ok "Completed ${APP} installation"

# Final message with configuration instructions
cat <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 🟢 ${APP} installation complete!

 ⚠️  IMPORTANT: Configuration required before use

 1. Edit the .env file with your Proxmox credentials:
    nano /opt/pulse/.env

 2. Required settings:
    - PROXMOX_NODE_1_NAME=Your Node Name
    - PROXMOX_NODE_1_HOST=https://your-proxmox-ip:8006
    - PROXMOX_NODE_1_TOKEN_ID=root@pam!pulse
    - PROXMOX_NODE_1_TOKEN_SECRET=your-token-secret

 3. Start Pulse with:
    systemctl start pulse

 Access URL: http://${IP}:7654 (after starting)
 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF 