#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Your Name Here | Co-Author: Another Name
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/byparr/byparr

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Set root password to 'root'
msg_info "Setting default root password"
echo "root:root" | chpasswd
if [[ $? -ne 0 ]]; then
  msg_error "Failed to set root password. Please check container permissions."
  exit 1
fi
msg_ok "Root password has been set to 'root'"

# Set up auto-login for root
msg_info "Setting up auto-login"
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat <<EOF >/etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear --keep-baud tty%I 115200,38400,9600 \$TERM
EOF
systemctl daemon-reload
if [[ $? -ne 0 ]]; then
  msg_error "Failed to reload systemd daemon. Auto-login may not work."
  exit 1
fi
msg_ok "Set up auto-login"

msg_info "Installing Dependencies"
$STD apt-get update
$STD apt-get install -y curl
$STD apt-get install -y git
$STD apt-get install -y python3-full
$STD apt-get install -y python3-pip
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

msg_info "Installing UV Package Manager"
$STD curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env
msg_ok "Installed UV Package Manager"

msg_info "Cloning Byparr Repository"
if [[ ! -d /Byparr ]]; then
  $STD git clone https://github.com/byparr/byparr /Byparr
  if [[ $? -ne 0 ]]; then
    msg_error "Failed to clone Byparr repository. Please check network connectivity."
    exit 1
  fi
else {
  msg_info "Byparr repository already exists. Pulling latest changes."
  cd /Byparr && git pull
}
cd /Byparr
CURRENT_VERSION=$(git rev-parse HEAD)
mkdir -p /opt
echo "${CURRENT_VERSION}" > /opt/${APPLICATION}_version.txt
msg_ok "Cloned Byparr Repository"

msg_info "Installing Byparr Dependencies"
$STD cd /Byparr && uv sync --group test
msg_ok "Installed Byparr Dependencies"

msg_info "Setting up Run Script"
cat <<EOF > /Byparr/run.sh
#!/bin/bash
cd /Byparr
source $HOME/.local/bin/env
uv run python -m byparr
EOF
chmod +x /Byparr/run.sh
msg_ok "Created Run Script"

msg_info "Creating Service"
cat <<EOF > /etc/systemd/system/byparr.service
[Unit]
Description=Byparr Service
After=network.target

[Service]
SyslogIdentifier=byparr
Restart=always
RestartSec=5
Type=simple
User=root
WorkingDirectory=/Byparr
ExecStart=/bin/bash /Byparr/run.sh
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

# Make sure the service is enabled and started
systemctl daemon-reload
systemctl enable byparr.service
systemctl start byparr.service
# Verify service is running
if systemctl is-active --quiet byparr.service; then
  msg_ok "Created and started Byparr service"
else
  msg_error "Failed to start Byparr service. Check logs for details."
  systemctl status byparr.service
  # Try again with more debugging
  msg_info "Attempting to restart service with more debugging"
  cat /Byparr/run.sh
  chmod +x /Byparr/run.sh
  systemctl restart byparr.service
  sleep 2
  systemctl status byparr.service
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"