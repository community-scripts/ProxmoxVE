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
$STD apt-get install -y make
$STD apt-get install -y g++
$STD apt-get install -y gcc
$STD apt-get install -y ca-certificates
$STD apt-get install -y gnupg
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g npm@latest
$STD npm install -g yarn
msg_ok "Installed Node.js"

RELEASE=$(curl -s https://api.github.com/repos/hywax/mafl/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
msg_info "Installing Mafl v${RELEASE}"
wget -q https://github.com/hywax/mafl/archive/refs/tags/v${RELEASE}.tar.gz
tar -xzf v${RELEASE}.tar.gz
mkdir -p /opt/mafl/data
wget -q -O /opt/mafl/data/config.yml https://raw.githubusercontent.com/hywax/mafl/main/.example/config.yml
mv mafl-${RELEASE}/* /opt/mafl
rm -rf mafl-${RELEASE}
cd /opt/mafl
export NUXT_TELEMETRY_DISABLED=true
$STD yarn install
$STD yarn build
msg_ok "Installed Mafl v${RELEASE}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/mafl.service
[Unit]
Description=Mafl
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
WorkingDirectory=/opt/mafl/
ExecStart=yarn preview

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mafl
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
