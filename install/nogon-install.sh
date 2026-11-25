#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/asciimoo/nogon

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "nogon" "asciimoo/nogon" "singlefile" "latest" "/usr/local/bin" "nogon_*_linux_$(arch_resolve)"

msg_info "Configuring Nogon"
mkdir -p /opt/nogon/data /etc/nogon
LOCAL_IP=$(hostname -I | awk '{print $1}')
cat <<EOF >/etc/nogon/config.yaml
app:
  directory: '/opt/nogon/data'
server:
  address: '0.0.0.0:4433'
  base_url: 'http://${LOCAL_IP}:4433'
EOF
msg_ok "Configured Nogon"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/nogon.service
[Unit]
Description=Nogon Search Engine
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/nogon listen --config /etc/nogon/config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now nogon
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
