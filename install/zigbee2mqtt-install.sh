#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.zigbee2mqtt.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git \
  make \
  g++ \
  gcc \
  ca-certificates
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="pnpm@latest" setup_nodejs

msg_info "Setting up Zigbee2MQTT"
cd /opt
RELEASE=$(curl -fsSL https://api.github.com/repos/Koenkk/zigbee2mqtt/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
curl -fsSL "https://github.com/Koenkk/zigbee2mqtt/archive/refs/tags/${RELEASE}.zip" -o "${RELEASE}.zip"
$STD unzip ${RELEASE}.zip
mv zigbee2mqtt-${RELEASE} /opt/zigbee2mqtt
cd /opt/zigbee2mqtt/data
mv configuration.example.yaml configuration.yaml
cd /opt/zigbee2mqtt
$STD pnpm install --no-frozen-lockfile
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
systemctl enable -q --now zigbee2mqtt
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
