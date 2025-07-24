#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Forceu/Gokapi

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "gokapi" "Forceu/Gokapi" "prebuild" "latest" "/opt/gokapi" "gokapi-linux_amd64.zip"

msg_info "Configuring Gokapi"
mkdir -p /opt/gokapi/{data,config}
chmod +x /opt/gokapi/gokapi-linux_amd64
msg_ok "Configured Gokapi"

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
