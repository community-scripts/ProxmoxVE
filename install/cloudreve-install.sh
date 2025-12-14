#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://cloudreve.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "cloudreve" "cloudreve/cloudreve" "prebuild" "latest" "/opt/cloudreve" "*linux_amd64.tar.gz"

msg_info "Setup Service"
cat <<EOF >/etc/systemd/system/cloudreve.service
[Unit]
Description=Cloudreve Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/cloudreve/cloudreve
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now cloudreve
msg_ok "Service Setup"

motd_ssh
customize
cleanup_lxc
