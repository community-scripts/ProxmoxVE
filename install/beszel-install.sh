#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Michelle Zitzerman (Sinofage)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://beszel.dev/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "beszel" "henrygd/beszel" "prebuild" "latest" "/opt/beszel" "beszel_linux_amd64.tar.gz"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/beszel-hub.service
[Unit]
Description=Beszel Hub Service
After=network.target

[Service]
ExecStart=/opt/beszel/beszel serve --http "0.0.0.0:8090"
WorkingDirectory=/opt/beszel
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now beszel-hub
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
