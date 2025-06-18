#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://dashy.to/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs

RELEASE=$(curl -fsSL https://api.github.com/repos/Lissy93/dashy/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
msg_info "Installing Dashy ${RELEASE} (Patience)"
mkdir -p /opt/dashy
curl -fsSL "https://github.com/Lissy93/dashy/archive/refs/tags/${RELEASE}.tar.gz" | tar -xz -C /opt/dashy --strip-components=1
cd /opt/dashy
$STD npm install
$STD npm run build
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Dashy ${RELEASE}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/dashy.service
[Unit]
Description=dashy

[Service]
Type=simple
WorkingDirectory=/opt/dashy
ExecStart=/usr/bin/npm start
[Install]
WantedBy=multi-user.target
EOF
systemctl -q --now enable dashy
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
