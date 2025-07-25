#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Lucas Zampieri (zampierilucas) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Cleanuparr/Cleanuparr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "Cleanuparr" "Cleanuparr/Cleanuparr" "prebuild" "latest" "/opt/cleanuparr" "*linux-amd64.zip"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/cleanuparr.service
[Unit]
Description=Cleanuparr Daemon
After=syslog.target network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cleanuparr
ExecStart=/opt/cleanuparr/Cleanuparr
Restart=on-failure
RestartSec=5
Environment="PORT=11011"
Environment="CONFIG_DIR=/opt/cleanuparr/config"

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cleanuparr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
