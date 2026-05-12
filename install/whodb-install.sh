#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://whodb.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "whodb" "clidey/whodb" "singlefile" "latest" "/opt/whodb" "whodb-*-linux-amd64"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/whodb.service
[Unit]
Description=WhoDB Database Management
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/whodb
ExecStart=/opt/whodb/whodb
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now whodb
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
