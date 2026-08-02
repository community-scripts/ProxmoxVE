#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/nezhahq/nezha

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "nezha" "nezhahq/nezha" "prebuild" "latest" "/opt/nezha" "dashboard-linux-amd64.zip"

msg_info "Preparing Application Files"
if [[ -f /opt/nezha/dashboard-linux-amd64 ]]; then
  mv /opt/nezha/dashboard-linux-amd64 /opt/nezha/dashboard
fi
chmod +x /opt/nezha/dashboard
mkdir -p /opt/nezha/data
msg_ok "Prepared Application Files"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/nezha.service
[Unit]
Description=Nezha Monitoring Dashboard
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/nezha
ExecStart=/opt/nezha/dashboard
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now nezha
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
