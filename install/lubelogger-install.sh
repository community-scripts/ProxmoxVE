#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: kristocopani
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    curl \
    wget \
    mc \
    zip \
    jq
msg_ok "Installed Dependencies"


msg_info "Installing LubeLogger"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/hargata/lubelog/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
RELEASE_TRIMMED=$(echo "${RELEASE}" | tr -d ".")
wget -q https://github.com/hargata/lubelog/releases/download/v${RELEASE}/LubeLogger_v${RELEASE_TRIMMED}_linux_x64.zip
mkdir /opt/lubelogger
$STD unzip -qq LubeLogger_${RELEASE_TRIMMED}_linux_x64.zip -d lubelogger
chmod 700 /opt/lubelogger/CarCareTracker
cp /opt/lubelogger/appsettings.json /opt/lubelogger/appsettings_bak.json
jq '.Kestrel = {"Endpoints": {"Http": {"Url": "http://0.0.0.0:5000"}}}' /opt/lubelogger/appsettings_bak.json > /opt/lubelogger/appsettings.json
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed LubeLogger"

msg_info "Creating Service"
service_path="/etc/systemd/system/lubelogger.service"
echo "[Unit]
Description=LubeLogger Daemon
After=network.target

[Service]
User=root

Type=simple
WorkingDirectory=/opt/lubelogger
ExecStart=/opt/lubelogger/CarCareTracker
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target" >$service_path

systemctl enable --now -q lubelogger.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/lubelogger/appsettings_bak.json
rm -rf /opt/LubeLogger_v${RELEASE_TRIMMED}_linux_x64.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
