#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/usememos/memos

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "memos" "usememos/memos" "prebuild" "latest" "/opt/memos" "memos*linux_amd64.tar.gz"
mkdir -p /opt/memos_data

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/memos.service
[Unit]
Description=Memos Server
After=network.target

[Service]
ExecStart=/opt/memos/memos
Environment="MEMOS_MODE=prod"
Environment="MEMOS_PORT=9030"
Environment="MEMOS_DATA=/opt/memos_data"
WorkingDirectory=/opt/memos
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now memos
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
