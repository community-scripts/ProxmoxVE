#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/StuffAnThings/qbit_manage

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "qbit-manage" "StuffAnThings/qbit_manage" "singlefile" "latest" "/opt/qbit-manage" "qbit-manage-linux-$(arch_resolve amd64 arm64)"

msg_info "Configuring qBit Manage"
mkdir -p /opt/qbit-manage_data
curl -fsSL "https://raw.githubusercontent.com/StuffAnThings/qbit_manage/master/config/config.yml.sample" -o /opt/qbit-manage_data/config.yml
cat <<EOF >/opt/qbit-manage.env
QBT_CONFIG_DIR=/opt/qbit-manage_data
QBT_WEB_SERVER=true
QBT_HOST=0.0.0.0
QBT_PORT=8181
QBT_SCHEDULE=1440
EOF
chmod 600 /opt/qbit-manage.env
msg_ok "Configured qBit Manage"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/qbit-manage.service
[Unit]
Description=qBit Manage
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/qbit-manage_data
EnvironmentFile=/opt/qbit-manage.env
ExecStart=/opt/qbit-manage/qbit-manage
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now qbit-manage
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
