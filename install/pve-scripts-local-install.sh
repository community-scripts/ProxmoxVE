#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

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
  sshpass \
  rsync \
  expect
msg_ok "Dependencies installed."

NODE_VERSION=22 setup_nodejs
fetch_and_deploy_gh_release "ProxmoxVE-Local" "community-scripts/ProxmoxVE-Local"

msg_info "Installing PVE Scripts local"
cd /opt/ProxmoxVE-Local
$STD npm install
cp .env.example .env
mkdir -p data
chmod 755 data

$STD npx prisma generate
$STD npx prisma migrate deploy

$STD npm run build
msg_ok "Installed PVE Scripts local"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/pvescriptslocal.service
[Unit]
Description=PVEScriptslocal Service
After=network.target

[Service]
WorkingDirectory=/opt/ProxmoxVE-Local
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
Environment=NODE_ENV=production
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now pvescriptslocal
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
