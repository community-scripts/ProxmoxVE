#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Jakub Matraszek (jmatraszek)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.cross-seed.org

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs

msg_info "Setup Cross-Seed"
$STD npm install cross-seed@latest -g
$STD cross-seed gen-config
msg_ok "Setup Cross-Seed"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/cross-seed.service
[Unit]
Description=Cross-Seed daemon Service
After=network.target

[Service]
ExecStart=cross-seed daemon
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cross-seed
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
