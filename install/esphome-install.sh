#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
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
$STD apt-get install -y git
msg_ok "Installed Dependencies"

msg_info "Updating Python3"
$STD apt-get install -y \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Updated Python3"

msg_info "Installing ESPHome"
mkdir /root/config
$STD pip install esphome tornado esptool
msg_ok "Installed ESPHome"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/esphomeDashboard.service
[Unit]
Description=ESPHome Dashboard
After=network.target

[Service]
ExecStart=/usr/local/bin/esphome dashboard /root/config/
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now esphomeDashboard.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
