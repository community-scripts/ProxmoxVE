#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://uptime.kuma.pet/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y git
$STD apt-get install -y ca-certificates
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing Uptime Kuma"
$STD git clone https://github.com/louislam/uptime-kuma.git
mv uptime-kuma /opt/uptime-kuma
cd /opt/uptime-kuma
$STD npm run setup
msg_ok "Installed Uptime Kuma"

msg_info "Creating Service"
service_path="/etc/systemd/system/uptime-kuma.service"
echo "[Unit]
Description=uptime-kuma

[Service]
Type=simple
Restart=always
User=root
WorkingDirectory=/opt/uptime-kuma
ExecStart=/usr/bin/npm start

[Install]
WantedBy=multi-user.target" >$service_path
$STD systemctl enable --now uptime-kuma
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
