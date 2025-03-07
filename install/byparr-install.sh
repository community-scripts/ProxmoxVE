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

# Enable automatic login for root user
msg_info "Setting up auto-login for root user"
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat <<EOF > /etc/systemd/system/getty@tty1.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear --keep-baud tty%I 115200,38400,9600 \$TERM
EOF
systemctl daemon-reload
msg_ok "Set up auto-login for root user"

msg_info "Installing Dependencies"
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
$STD git clone https://github.com/byparr/byparr /Byparr
cd /Byparr
# Store the current version for update tracking
CURRENT_VERSION=$(git rev-parse HEAD)
echo "${CURRENT_VERSION}" > /opt/${APPLICATION}_version.txt
msg_ok "Cloned Byparr Repository"

msg_info "Installing Byparr Dependencies"
$STD uv sync --group test
msg_ok "Installed Byparr Dependencies"

msg_info "Setting up Run Script"
cat <<EOF > /Byparr/run.sh
#!/bin/bash
cd /Byparr
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
Type=simple
User=root
WorkingDirectory=/Byparr
ExecStart=/Byparr/run.sh
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now byparr.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned" 