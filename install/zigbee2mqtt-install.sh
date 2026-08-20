#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.zigbee2mqtt.io/ | Github: https://github.com/Koenkk/zigbee2mqtt

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb_based() {
  msg_info "Installing Dependencies"
  $STD apt install -y \
    git \
    build-essential
  msg_ok "Installed Dependencies"

  NODE_VERSION="24" NODE_MODULE="pnpm@$(curl -fsSL https://raw.githubusercontent.com/Koenkk/zigbee2mqtt/master/package.json | jq -r '.packageManager | split("@")[1]')" setup_nodejs
  fetch_and_deploy_gh_release "Zigbee2MQTT" "Koenkk/zigbee2mqtt" "tarball" "latest" "/opt/zigbee2mqtt"

  msg_info "Setting up Zigbee2MQTT"
  mv /opt/zigbee2mqtt/data/configuration.example.yaml /opt/zigbee2mqtt/data/configuration.yaml
  cd /opt/zigbee2mqtt
  echo "packageImportMethod: hardlink" >>./pnpm-workspace.yaml
  $STD pnpm install --no-frozen-lockfile
  $STD pnpm build
  msg_ok "Setup Zigbee2MQTT"

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
}

setup_alpine() {
  msg_info "Installing Alpine-Zigbee2MQTT"
  mkdir -p /root/.z2m /etc/zigbee2mqtt
  $STD apk add zigbee2mqtt
  ln -s /etc/zigbee2mqtt/ /root/.z2m
  chown -R root:root /etc/zigbee2mqtt /root/.z2m
  sed -i -e 's/#datadir="\/var\/lib\/zigbee2mqtt"/datadir="\/etc\/zigbee2mqtt"/' -e 's/#command_user="zigbee2mqtt"/command_user="root"/' /etc/conf.d/zigbee2mqtt
  $STD rc-update add zigbee2mqtt
  $STD rc-service zigbee2mqtt restart
  msg_ok "Installed Alpine-Zigbee2MQTT"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
