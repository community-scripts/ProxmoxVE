#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://esphome.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y git
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv

msg_info "Setting up Virtual Environment"
mkdir -p /opt/esphome
mkdir -p /root/config
cd /opt/esphome
$STD uv venv /opt/esphome/.venv
$STD /opt/esphome/.venv/bin/python -m ensurepip --upgrade
$STD /opt/esphome/.venv/bin/python -m pip install --upgrade pip
$STD /opt/esphome/.venv/bin/python -m pip install esphome tornado esptool
msg_ok "Setup and Installed ESPHome"

msg_info "Linking esphome to /usr/local/bin"
rm -f /usr/local/bin/esphome
ln -s /opt/esphome/.venv/bin/esphome /usr/local/bin/esphome
msg_ok "Linked esphome binary"

msg_info "Creating Service"
mkdir -p /root/config
cat <<EOF >/etc/systemd/system/esphomeDashboard.service
[Unit]
Description=ESPHome Dashboard
After=network.target

[Service]
ExecStart=/opt/esphome/.venv/bin/esphome dashboard /root/config/
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now esphomeDashboard
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
