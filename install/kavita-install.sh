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
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

msg_info "Installing Kavita"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/Kareadita/Kavita/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
$STD tar -xvzf <(curl -fsSL https://github.com/Kareadita/Kavita/releases/download/$RELEASE/kavita-linux-x64.tar.gz) --no-same-owner
msg_ok "Installed Kavita"

msg_info "Creating Service"
service_path="/etc/systemd/system/kavita.service"
echo "[Unit]
Description=Kavita Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/Kavita
ExecStart=/opt/Kavita/Kavita
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target" >$service_path
chmod +x /opt/Kavita/* && chown root /opt/Kavita/*
systemctl enable --now -q kavita.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
