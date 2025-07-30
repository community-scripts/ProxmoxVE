#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://lubelogger.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "lubelogger" "hargata/lubelog" "prebuild" "latest" "/opt/lubelogger" "LubeLogger*linux_x64.zip"

msg_info "Configuring LubeLogger"
cd /opt/lubelogger
chmod 700 /opt/lubelogger/CarCareTracker
cp /opt/lubelogger/appsettings.json /opt/lubelogger/appsettings_bak.json
jq '.Kestrel = {"Endpoints": {"Http": {"Url": "http://0.0.0.0:5000"}}}' /opt/lubelogger/appsettings_bak.json >/opt/lubelogger/appsettings.json
msg_ok "Configured LubeLogger"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/lubelogger.service
[Unit]
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
WantedBy=multi-user.target
EOF

systemctl enable -q --now lubelogger
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/lubelogger/appsettings_bak.json
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
