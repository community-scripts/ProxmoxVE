#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Michelle Zitzerman (Sinofage)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://beszel.dev/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  tar \
  sudo \
  mc
msg_ok "Installed Dependencies"

msg_info "Installing Beszel"
mkdir -p /opt/beszel 
curl -sL "https://github.com/henrygd/beszel/releases/latest/download/beszel_$(uname -s)_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/armv6l/arm/' -e 's/armv7l/arm/' -e 's/aarch64/arm64/').tar.gz" | tar -xz -O beszel | tee /opt/beszel/beszel >/dev/null 
chmod +x /opt/beszel/beszel
msg_ok "Installed Beszel"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/beszel-hub.service
[Unit]
Description=Beszel Hub Service
After=network.target

[Service]
ExecStart=/opt/beszel/beszel serve --http "0.0.0.0:8090"
WorkingDirectory=/opt/beszel
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now beszel-hub.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"