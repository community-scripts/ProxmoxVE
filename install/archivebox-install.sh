#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://archivebox.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git \
  expect \
  libssl-dev \
  libldap2-dev \
  libsasl2-dev \
  procps \
  dnsutils \
  ripgrep
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv
NODE_VERSION="22" install_node_and_modules

msg_info "Installing ArchiveBox"

mkdir -p /opt/archivebox/{data,.npm,.cache,.local}
adduser --system --shell /bin/bash --gecos 'Archive Box User' --group --disabled-password --home /home/archivebox archivebox

sudo -u archivebox bash
cd /opt/archivebox
$STD uv venv /opt/archivebox/.venv
$STD /opt/archivebox/.venv/bin/python -m ensurepip --upgrade
$STD /opt/archivebox/.venv/bin/python -m pip install --upgrade pip
$STD /opt/archivebox/.venv/bin/python -m pip install archivebox playwright

chown -R archivebox:archivebox /opt/archivebox
chmod -R 755 /opt/archivebox

sudo -u archivebox /opt/archivebox/.venv/bin/playwright install-deps chromium
sudo -u archivebox /opt/archivebox/.venv/bin/playwright install chromium

msg_ok "Installed ArchiveBox & Playwright"

msg_info "Initial ArchiveBox Setup"
expect <<EOF
set timeout -1
log_user 0

spawn sudo -u archivebox /opt/archivebox/.venv/bin/playwright install chromium
expect eof

spawn sudo -u archivebox /opt/archivebox/.venv/bin/archivebox setup

expect "Username"
send "\r"

expect "Email address"
send "\r"

expect "Password"
send "helper-scripts.com\r"

expect "Password (again)"
send "helper-scripts.com\r"

expect eof
EOF
msg_ok "Initialized ArchiveBox"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/archivebox.service
[Unit]
Description=ArchiveBox Server
After=network.target

[Service]
User=archivebox
WorkingDirectory=/opt/archivebox/data
ExecStart=/opt/archivebox/.venv/bin/archivebox server 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now archivebox
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
