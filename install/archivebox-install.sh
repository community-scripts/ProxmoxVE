#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
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
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  git \
  expect \
  libssl-dev \
  libldap2-dev \
  libsasl2-dev \
  procps \
  dnsutils \
  ripgrep
msg_ok "Installed Dependencies"

msg_info "Installing Python Dependencies"
$STD apt-get install -y \
  python3-pip \
  python3-ldap \
  python3-msgpack \
  python3-regex
msg_ok "Installed Python Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Installing Playwright"
$STD pip install playwright 
$STD playwright install-deps chromium 
msg_ok "Installed Playwright"

msg_info "Installing Chromium and ArchiveBox"
mkdir -p /opt/archivebox/{data,.npm,.cache,.local}
$STD adduser --system --shell /bin/bash --gecos 'Archive Box User' --group --disabled-password --home /home/archivebox archivebox
chown -R archivebox:archivebox /opt/archivebox/{data,.npm,.cache,.local}
chmod -R 755 /opt/archivebox/data
$STD pip install archivebox
cd /opt/archivebox/data
expect <<EOF
set timeout -1
log_user 0

spawn sudo -u archivebox playwright install chromium
spawn sudo -u archivebox archivebox setup

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
msg_ok "Installed ArchiveBox"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/archivebox.service
[Unit]
Description=ArchiveBox Server
After=network.target

[Service]
User=archivebox
WorkingDirectory=/opt/archivebox/data
ExecStart=/usr/local/bin/archivebox server 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now archivebox.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
