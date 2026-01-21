#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: luismco
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ThePhaseless/Byparr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt -y install \
    xauth \
    xvfb \
    scrot \
    chromium \
    chromium-driver \
    ca-certificates
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "Byparr" "ThePhaseless/Byparr"
setup_uv

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/byparr.service
[Unit]
Description=Byparr
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/Byparr
ExecStart=/usr/local/bin/uv run python3 main.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now byparr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
