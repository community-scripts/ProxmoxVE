#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Jakub Matraszek (jmatraszek)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.cross-seed.org

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  gnupg
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_23.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Setup Node.js Repository"

msg_info "Setting up Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Setup Node.js"

msg_info "Setup Cross-Seed"
$STD npm install cross-seed@latest -g
$STD cross-seed gen-config
msg_ok "Setup Cross-Seed"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/cross-seed.service
[Unit]
Description=Cross-Seed daemon Service
After=network.target

[Service]
ExecStart=cross-seed daemon
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cross-seed
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
