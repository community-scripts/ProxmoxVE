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

RELEASE=$(curl -s https://api.github.com/repos/TriliumNext/Notes/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')

msg_info "Installing TriliumNext"
wget -q https://github.com/TriliumNext/Notes/releases/download/${RELEASE}/TriliumNextNotes-${RELEASE}-server-linux-x64.tar.xz
tar -xf TriliumNextNotes-${RELEASE}-server-linux-x64.tar.xz
mv trilium-linux-x64-server /opt/trilium
msg_ok "Installed TriliumNext"

msg_info "Creating Service"
service_path="/etc/systemd/system/trilium.service"

echo "[Unit]
Description=Trilium Daemon
After=syslog.target network.target

[Service]
User=root
Type=simple
ExecStart=/opt/trilium/trilium.sh
WorkingDirectory=/opt/trilium/
TimeoutStopSec=20
Restart=always

[Install]
WantedBy=multi-user.target" >$service_path
systemctl enable --now -q trilium
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
rm -rf TriliumNextNotes-${RELEASE}-server-linux-x64.tar.xz
msg_ok "Cleaned"
