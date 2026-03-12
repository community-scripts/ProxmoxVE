#!/usr/bin/env bash

# Author: BIllyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/openclaw/openclaw

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  wget \
  ca-certificates \
  build-essential \
  python3 \
  git
msg_ok "Installed Dependencies"

# Setup Node.js 22 (required by OpenClaw)
NODE_VERSION="22" setup_nodejs

msg_info "Installing OpenClaw"
$STD npm install -g openclaw@latest
msg_ok "Installed OpenClaw"

msg_info "Creating Directories"
mkdir -p /opt/openclaw
mkdir -p /root/.openclaw
msg_ok "Created Directories"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openclaw.service
[Unit]
Description=OpenClaw Gateway - Personal AI Assistant
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/openclaw
Environment=NODE_ENV=production
ExecStart=/usr/bin/openclaw gateway --port 18789
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=openclaw

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now openclaw
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
