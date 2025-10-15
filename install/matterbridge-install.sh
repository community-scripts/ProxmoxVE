#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Luligu/matterbridge/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Install Matterbridge"
mkdir -p /root/Matterbridge
NODE_VERSION="22"
NODE_MODULE="matterbridge"
setup_nodejs
msg_ok "Installed Matterbridge"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/matterbridge.service
[Unit]
Description=matterbridge
After=network-online.target

[Service]
Type=simple
ExecStart=matterbridge -bridge -service
WorkingDirectory=/root/Matterbridge
StandardOutput=inherit
StandardError=inherit
Restart=always
RestartSec=10s
TimeoutStopSec=30s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now matterbridge
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
