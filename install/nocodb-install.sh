#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.nocodb.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "nocodb" "nocodb/nocodb" "singlefile" "latest" "/opt/nocodb/" "Noco-linux-x64"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/nocodb.service
echo "[Unit]
Description=nocodb

[Service]
Type=simple
Restart=always
User=root
WorkingDirectory=/opt/nocodb
ExecStart=/opt/nocodb/./nocodb

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now nocodb
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
