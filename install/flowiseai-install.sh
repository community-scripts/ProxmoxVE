#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y gpg
msg_ok "Installed Dependencies"

msg_info "Installing Node.js"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Installing FlowiseAI (Patience)"
$STD npm install -g flowise
mkdir -p /opt/flowiseai
wget -q https://raw.githubusercontent.com/FlowiseAI/Flowise/main/packages/server/.env.example -O /opt/flowiseai/.env
msg_ok "Installed FlowiseAI"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/flowise.service
[Unit]
Description=FlowiseAI
After=network.target

[Service]
EnvironmentFile=/opt/flowiseai/.env
ExecStart=npx flowise start
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now flowise.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
