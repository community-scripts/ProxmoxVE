#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://n8n.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  ca-certificates
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing n8n (Patience)"
$STD npm install --global patch-package
$STD npm install --global n8n
msg_ok "Installed n8n"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/n8n.service
[Unit]
Description=n8n

[Service]
Type=simple
Environment="N8N_SECURE_COOKIE=false"
ExecStart=n8n start
[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable --now n8n
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
