#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Brandawg93/PeaNUT/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing NUT"
$STD apt install -y nut-client
msg_ok "Installed NUT"

NODE_VERSION="22" NODE_MODULE="pnpm" setup_nodejs
fetch_and_deploy_gh_release "peanut" "Brandawg93/PeaNUT" "tarball" "latest" "/opt/peanut"

msg_info "Setup Peanut"
cd /opt/peanut
$STD pnpm i
$STD pnpm run build:local
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
msg_ok "Setup Peanut"

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
systemctl enable -q --now peanut
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
