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
$STD apt install -y \
  git \
  make \
  g++ \
  gcc \
  ca-certificates \
  jq
msg_ok "Installed Dependencies"

NODE_VERSION="24" NODE_MODULE="pnpm@$(curl -fsSL https://raw.githubusercontent.com/Koenkk/zigbee2mqtt/master/package.json | jq -r '.packageManager | split("@")[1]')" setup_nodejs

fetch_and_deploy_gh_release "Zigbee2MQTT" "Koenkk/zigbee2mqtt" "tarball" "latest" "/opt/zigbee2mqtt"

msg_info "Setting up Zigbee2MQTT"
cd /opt/zigbee2mqtt/data || exit
mv configuration.example.yaml configuration.yaml
cd /opt/zigbee2mqtt || exit
echo "packageImportMethod: hardlink" >>./pnpm-workspace.yaml
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
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
