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

msg_info "Installing Gokapi"
LATEST=$(curl -sL https://api.github.com/repos/Forceu/Gokapi/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
mkdir -p /opt/gokapi/{data,config}
wget -q https://github.com/Forceu/Gokapi/releases/download/$LATEST/gokapi-linux_amd64.zip
unzip -q gokapi-linux_amd64.zip -d /opt/gokapi
rm gokapi-linux_amd64.zip
chmod +x /opt/gokapi/gokapi-linux_amd64
msg_ok "Installed Gokapi"

msg_info "Creating Service" 
cat <<EOF >/etc/systemd/system/gokapi.service
[Unit]
Description=gokapi

[Service]
Type=simple
Environment=GOKAPI_DATA_DIR=/opt/gokapi/data
Environment=GOKAPI_CONFIG_DIR=/opt/gokapi/config
ExecStart=/opt/gokapi/gokapi-linux_amd64

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gokapi
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
