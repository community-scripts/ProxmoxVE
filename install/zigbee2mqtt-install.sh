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
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  git \
  make \
  g++ \
  gcc \
  ca-certificates \
  gnupg
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Installing pnpm"
$STD npm install -g pnpm
msg_ok "Installed pnpm"

msg_info "Setting up Zigbee2MQTT"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/Koenkk/zigbee2mqtt/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q "https://github.com/Koenkk/zigbee2mqtt/archive/refs/tags/${RELEASE}.zip"
unzip -q ${RELEASE}.zip
mv zigbee2mqtt-${RELEASE} /opt/zigbee2mqtt
cd /opt/zigbee2mqtt/data
mv configuration.example.yaml configuration.yaml
cd /opt/zigbee2mqtt
$STD pnpm install --frozen-lockfile
$STD pnpm build
msg_ok "Installed Zigbee2MQTT"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/zigbee2mqtt.service
[Unit]
Description=zigbee2mqtt
After=network.target
[Service]
Environment=NODE_ENV=production
ExecStart=/usr/bin/pnpm start
WorkingDirectory=/opt/zigbee2mqtt
StandardOutput=inherit
StandardError=inherit
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now zigbee2mqtt.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
