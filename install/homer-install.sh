#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y pip
msg_ok "Installed Dependencies"

msg_info "Installing Homer"
mkdir -p /opt/homer
cd /opt/homer
wget -q https://github.com/bastienwirtz/homer/releases/latest/download/homer.zip
$STD unzip homer.zip
rm -rf homer.zip
cp assets/config.yml.dist assets/config.yml
msg_ok "Installed Homer"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/homer.service
[Unit]
Description=Homer Dashboard
After=network-online.target
[Service]
Type=simple
WorkingDirectory=/opt/homer
ExecStart=python3 -m http.server 8010
[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable --now homer
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
