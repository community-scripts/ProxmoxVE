#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ThePhaseless/Byparr

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

LOG_FILE="/var/log/byparr-install.log"
echo "Starting Byparr installation at $(date)" > "$LOG_FILE"

# Installing Dependencies
msg_info "Installing Dependencies"
$STD apt-get update
$STD apt-get install -y curl sudo mc apt-transport-https gpg xvfb git
msg_ok "Installed Dependencies"

# Installing Chrome
msg_info "Installing Chrome"
$STD wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
$STD apt-get update
$STD apt-get install -y google-chrome-stable
msg_ok "Installed Chrome"

# Installing UV Package Manager
msg_info "Installing UV Package Manager"
$STD curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env
msg_ok "Installed UV Package Manager"

# Installing Byparr
msg_info "Installing Byparr"
$STD git clone https://github.com/ThePhaseless/Byparr.git /opt/byparr
cd /opt/byparr
$STD uv sync --group test
msg_ok "Installed Byparr"

# Creating Service
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/byparr.service
[Unit]
Description=Byparr
After=network.target
[Service]
SyslogIdentifier=byparr
Restart=always
RestartSec=5
Type=simple
Environment="LOG_LEVEL=info"
Environment="CAPTCHA_SOLVER=none"
WorkingDirectory=/opt/byparr
ExecStart=/bin/bash -c "uv sync && ./cmd.sh"
TimeoutStopSec=60
[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable --now byparr.service
msg_ok "Created Service"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

echo "Byparr installation completed successfully at $(date)" >> "$LOG_FILE"