#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/oauth2-proxy/oauth2-proxy/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "oauth2-proxy" "oauth2-proxy/oauth2-proxy" "prebuild" "latest" "/opt/oauth2-proxy" "oauth2-proxy*linux-amd64.tar.gz"
touch /opt/oauth2-proxy/config.toml

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/oauth2-proxy.service
[Unit]
Description=OAuth2-Proxy Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/oauth2-proxy
ExecStart=/opt/oauth2-proxy/oauth2-proxy --config config.toml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now oauth2-proxy
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
