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
fetch_and_deploy_gh_release "dashy" "Lissy93/dashy"

msg_info "Installing Dashy"
cd /opt/dashy
$STD npm install
$STD npm run build
msg_ok "Installed Dashy"

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
