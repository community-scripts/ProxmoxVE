#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
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
$STD apt-get install -y curl \
   sudo \
   mc \
   git \
   make \
   g++ \
   gcc \
   ca-certificates \
   gnupg
msg_ok "Installing Dependencies"

msg_info "Setup Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Setup Node.js Repository"

msg_info "Setup Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Setup Node.js"

msg_info "Setup Zigbee2MQTT Repository"
$STD git clone --depth 1 https://github.com/Koenkk/zigbee2mqtt.git /opt/zigbee2mqtt
msg_ok "Setup Zigbee2MQTT Repository"

read -r -p "Switch to Edge/dev branch? (y/N) " prompt
if [[ $prompt == "y" ]]; then
  DEV="y"
else
  DEV="n"
fi

msg_info "Setup Zigbee2MQTT"
cd /opt/zigbee2mqtt
if [[ $DEV == "y" ]]; then
$STD git fetch origin dev:dev
$STD git checkout dev
$STD git pull
$STD bash -c "$(wget -qO- https://get.pnpm.io/install.sh)" 
source /root/.bashrc
$STD pnpm install 
else
$STD npm ci 
fi
msg_ok "Setup Zigbee2MQTT"

msg_info "Creating Service"
service_path="/etc/systemd/system/zigbee2mqtt.service"
echo "[Unit]
Description=zigbee2mqtt
After=network.target
[Service]
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm start
WorkingDirectory=/opt/zigbee2mqtt
StandardOutput=inherit
StandardError=inherit
Restart=always
User=root
[Install]
WantedBy=multi-user.target" >$service_path
$STD systemctl enable zigbee2mqtt.service
msg_ok "Creating Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

