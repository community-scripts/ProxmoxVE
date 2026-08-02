#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://certimate.me/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "certimate" "certimate-go/certimate" "prebuild" "latest" "/opt/certimate" "certimate_*_linux_$(arch_resolve).zip"

msg_info "Creating Service"
cat <<'EOF' >/etc/systemd/system/certimate.service
[Unit]
Description=Certimate SSL Certificate Manager
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/certimate
ExecStart=/opt/certimate/certimate serve --http "0.0.0.0:8090"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now certimate
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
