#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck
# Co-Author: MrYadro
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
$STD apt-get install -y git
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

msg_info "Installing Recyclarr"
wget -q $(curl -s https://api.github.com/repos/recyclarr/recyclarr/releases/latest | grep download | grep linux-x64 | cut -d\" -f4)
tar -C /usr/local/bin -xJf recyclarr*.tar.xz
rm -rf recyclarr*.tar.xz
mkdir -p /root/.config/recyclarr
recyclarr config create
msg_ok "Installed Recyclarr"

msg_info "Creating Service"
service_path="/etc/systemd/system/recyclarr.service"
echo "[Unit]
Description=recyclarr service
After=syslog.target network-online.target
[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/recyclarr --config=/root/.config/recyclarr/
[Install]
WantedBy=multi-user.target" >$service_path
systemctl enable --now -q recyclarr.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
