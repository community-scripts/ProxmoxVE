#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
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
$STD apt-get install -y openjdk-17-jre
msg_ok "Installed Dependencies"

RELEASE=$(curl -s https://api.github.com/repos/gotson/komga/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')

msg_info "Installing Komga"
wget -q https://github.com/gotson/komga/releases/download/${RELEASE}/komga-${RELEASE}.jar
mv https://github.com/gotson/komga/releases/download/${RELEASE}/komga-${RELEASE}.jar /opt/komga
msg_ok "Installed TriliumNext"

msg_info "Creating Service"
service_path="/etc/systemd/system/komga.service"

echo "[Unit]
Description=Komga
After=syslog.target network.target

[Service]
User=root
Type=simple
ExecStart=java -jar -Xmx2g komga-${RELEASE}.jar
WorkingDirectory=/opt/komga/
TimeoutStopSec=20
Restart=always

[Install]
WantedBy=multi-user.target" >$service_path
systemctl enable --now -q komga
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
