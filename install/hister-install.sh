#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/asciimoo/hister

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "hister" "asciimoo/hister" "singlefile" "latest" "/usr/local/bin" "hister_*_linux_$(arch_resolve)"

msg_info "Configuring Hister"
mkdir -p /opt/hister/data /etc/hister
LOCAL_IP=$(hostname -I | awk '{print $1}')
cat <<EOF >/etc/hister/config.yaml
app:
  directory: '/opt/hister/data'
server:
  address: '0.0.0.0:4433'
  base_url: 'http://${LOCAL_IP}:4433'
EOF
msg_ok "Configured Hister"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/hister.service
[Unit]
Description=Hister Search Engine
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/hister listen --config /etc/hister/config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now hister
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
