#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pairdrop.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing PairDrop"
git clone -q https://github.com/schlagmichdoch/PairDrop.git /opt/pairdrop
cd /opt/pairdrop
$STD npm install
msg_ok "Installed PairDrop"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/pairdrop.service
[Unit]
Description=PairDrop Service
After=network.target

[Service]
ExecStart=npm start
WorkingDirectory=/opt/pairdrop
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pairdrop
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
