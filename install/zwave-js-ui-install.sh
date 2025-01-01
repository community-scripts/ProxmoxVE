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
  mc 
msg_ok "Installed Dependencies"

msg_info "Installing Z-Wave JS UI"
mkdir -p /opt/zwave-js-ui
mkdir -p /opt/zwave_store
cd /opt/zwave-js-ui
RELEASE=$(curl -s https://api.github.com/repos/zwave-js/zwave-js-ui/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q https://github.com/zwave-js/zwave-js-ui/releases/download/${RELEASE}/zwave-js-ui-${RELEASE}-linux.zip
unzip -q zwave-js-ui-${RELEASE}-linux.zip
cat <<EOF >/opt/.env
ZWAVEJS_EXTERNAL_CONFIG=/opt/zwave_store/.config-db
STORE_DIR=/opt/zwave_store
EOF
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Z-Wave JS UI"

msg_info "Creating Service"
cat <<EOF > /etc/systemd/system/zwave-js-ui.service
[Unit]
Description=zwave-js-ui
Wants=network-online.target
After=network-online.target

[Service]
User=root
WorkingDirectory=/opt/zwave-js-ui
ExecStart=/opt/zwave-js-ui/zwave-js-ui-linux
EnvironmentFile=/opt/.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now zwave-js-ui
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm zwave-js-ui-${RELEASE}-linux.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
