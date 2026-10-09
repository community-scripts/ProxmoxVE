#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/go-shiori/shiori

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "shiori" "go-shiori/shiori" "prebuild" "latest" "/opt/shiori" "shiori_Linux_$(arch_resolve "x86_64" "aarch64")_*.tar.gz"

msg_info "Configuring Shiori"
mkdir -p /opt/shiori/data
SECRET_KEY=$(tr -d '-' </proc/sys/kernel/random/uuid)
cat <<EOF >/opt/shiori/.env
SHIORI_DIR=/opt/shiori/data
SHIORI_HTTP_PORT=8080
SHIORI_HTTP_ADDRESS=0.0.0.0:
SHIORI_HTTP_SECRET_KEY=${SECRET_KEY}
EOF
msg_ok "Configured Shiori"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/shiori.service
[Unit]
Description=Shiori Bookmark Manager
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/shiori
EnvironmentFile=/opt/shiori/.env
ExecStart=/opt/shiori/shiori server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now shiori
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
