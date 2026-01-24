#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: isriam
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/clawdbot/clawdbot

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  ca-certificates \
  git \
  build-essential \
  python3 \
  python3-setuptools
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing Clawdbot"
$STD npm install -g clawdbot@latest
msg_ok "Installed Clawdbot"

msg_info "Creating Clawdbot Environment"
mkdir -p /opt/clawdbot
cat <<EOF >/opt/clawdbot/clawdbot.env
# Clawdbot Environment Configuration
# Configure via: clawdbot onboard
CLAWDBOT_HOME=/opt/clawdbot
EOF
msg_ok "Created Clawdbot Environment"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/clawdbot.service
[Unit]
Description=Clawdbot Personal AI Assistant
Documentation=https://github.com/clawdbot/clawdbot
After=network.target

[Service]
Type=simple
EnvironmentFile=/opt/clawdbot/clawdbot.env
WorkingDirectory=/opt/clawdbot
ExecStart=/usr/bin/clawdbot daemon
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
