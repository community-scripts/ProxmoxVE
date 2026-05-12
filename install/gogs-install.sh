#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gogs.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y git
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "gogs" "gogs/gogs" "prebuild" "latest" "/opt/gogs" "gogs_*_linux_amd64.tar.gz"

msg_info "Setting up Gogs"
mkdir -p /opt/gogs/{custom/conf,data,log}
msg_ok "Set up Gogs"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/gogs.service
[Unit]
Description=Gogs Git Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/gogs
ExecStart=/opt/gogs/gogs web
Restart=on-failure
RestartSec=5
Environment=USER=root
Environment=HOME=/root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gogs
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
