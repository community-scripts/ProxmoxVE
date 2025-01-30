#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: remz1337
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
$STD apt-get install -y gpg
msg_ok "Installed Dependencies"

msg_info "Installing Node.js"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Installing NUT"
$STD apt-get install -y nut-client
msg_ok "Installed NUT"

msg_info "Installing Peanut"
RELEASE=$(curl -sL https://api.github.com/repos/Brandawg93/PeaNUT/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
wget -qO peanut.tar.gz https://api.github.com/repos/Brandawg93/PeaNUT/tarball/${RELEASE}
mkdir -p /opt/peanut
tar -xzf peanut.tar.gz -C /opt/peanut --strip-components 1
rm peanut.tar.gz
cd /opt/peanut
$STD npm install -g pnpm
$STD pnpm i
$STD pnpm run build
cp -r .next/static .next/standalone/.next/
mkdir -p /opt/peanut/.next/standalone/config
mkdir -p /etc/peanut/
cat <<EOF >/etc/peanut/settings.yml
WEB_HOST: 0.0.0.0
WEB_PORT: 3000
NUT_HOST: 0.0.0.0
NUT_PORT: 3493
EOF
ln -sf /etc/peanut/settings.yml /opt/peanut/.next/standalone/config/settings.yml
msg_ok "Installed Peanut"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/peanut.service
[Unit]
Description=Peanut
After=network.target
[Service]
SyslogIdentifier=peanut
Restart=always
RestartSec=5
Type=simple
Environment="NODE_ENV=production"
#Environment="NUT_HOST=localhost"
#Environment="NUT_PORT=3493"
#Environment="WEB_HOST=0.0.0.0"
#Environment="WEB_PORT=3000"
WorkingDirectory=/opt/peanut
ExecStart=node /opt/peanut/.next/standalone/server.js
TimeoutStopSec=30
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now peanut.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
