#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/autobrr/qui

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "qui" "autobrr/qui" "prebuild" "latest" "/usr/local/bin" "qui_*_linux_x86_64.tar.gz"
chmod +x /usr/local/bin/qui
ln -sf /usr/local/bin/qui /usr/bin/qui
ln -sf /usr/local/bin/qui /opt/qui

msg_info "Creating Qui Service"
cat <<EOF >/etc/systemd/system/qui.service
[Unit]
Description=Qui - qBittorrent Web UI
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/qui serve
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now qui
msg_ok "Created Qui Service"

motd_ssh
customize
cleanup_lxc
