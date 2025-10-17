#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gnmyt/myspeed

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  ca-certificates \
  python3-setuptools
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "myspeed" "gnmyt/myspeed" "prebuild" "latest" "/opt/myspeed" "MySpeed-*.zip"

msg_info "Configuring MySpeed"
cd /opt/myspeed
$STD npm install
msg_ok "Installed MySpeed"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/myspeed.service
[Unit]
Description=MySpeed
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node server
Restart=always
User=root
Environment=NODE_ENV=production
WorkingDirectory=/opt/myspeed 

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now myspeed
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
