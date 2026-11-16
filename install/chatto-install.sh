#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/chattocorp/chatto

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "chatto" "chattocorp/chatto" "prebuild" "latest" "/opt/chatto" "chatto_Linux_$(arch_resolve x86_64 arm64).tar.gz"
chmod +x /opt/chatto/chatto

msg_info "Configuring Chatto"
mkdir -p /opt/chatto_data
cd /opt/chatto
$STD ./chatto init
mv /opt/chatto/chatto.toml /opt/chatto_data/chatto.toml
sed -i \
  -e "/^\[webserver\]/,/^\[/ s|^url = .*|url = 'http://${LOCAL_IP}:4000'|" \
  -e "/^\[nats.embedded\]/,/^\[/ s|^data_dir = .*|data_dir = '/opt/chatto_data/data'|" \
  -e '/^# \[operator_api\]$/,/^$/ { s|^# \[operator_api\]$|[operator_api]|; s|^# enabled = false$|enabled = true| }' \
  /opt/chatto_data/chatto.toml
msg_ok "Configured Chatto"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/chatto.service
[Unit]
Description=Chatto
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/chatto
ExecStart=/opt/chatto/chatto run -c /opt/chatto_data/chatto.toml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now chatto
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
