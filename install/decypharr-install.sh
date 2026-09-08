#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sirrobot01/decypharr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y fuse3
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "decypharr" "sirrobot01/decypharr" "prebuild" "latest" "/opt/decypharr" "decypharr_Linux_$(arch_resolve x86_64 arm64).tar.gz"
chmod +x /opt/decypharr/decypharr

msg_info "Creating Service"
mkdir -p /opt/decypharr_data
cat <<EOF >/etc/systemd/system/decypharr.service
[Unit]
Description=Decypharr
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/decypharr
ExecStart=/opt/decypharr/decypharr --config /opt/decypharr_data
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now decypharr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
