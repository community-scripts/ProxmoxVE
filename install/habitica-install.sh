#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/HabitRPG/habitica

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  libkrb5-dev \
  build-essential \
  git
curl -fsSL "http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb" -o "libssl1.1_1.1.1f-1ubuntu2_amd64.deb"
$STD dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb
msg_ok "Installed Dependencies"

NODE_VERSION="20" NODE_MODULE="gulp-cli,mocha,npm@10" setup_nodejs
fetch_and_deploy_gh_release "habitica" "HabitRPG/habitica" "tarball" "latest" "/opt/habitica"

msg_info "Setup ${APPLICATION}"
IPADDRESS=$(hostname -I | awk '{print $1}')
cd /opt/habitica
$STD npm i
$STD npm run postinstall
cp config.json.example config.json
sed -i "s/\"TRUSTED_DOMAINS\": \"/&http:\/\/$IPADDRESS:3000,/" config.json
$STD npm run client:build
$STD gulp build:prod

msg_ok "Setup ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/habitica-mongodb.service
[Unit]
Description=Habitica MongoDB Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/habitica
ExecStart=/usr/bin/npm run mongo:dev
Restart=always

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/habitica.service
[Unit]
Description=Habitica Service
After=habitica-mongodb.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/habitica
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/habitica-client.service
[Unit]
Description=Habitica Client Service
After=habitica.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/habitica
ExecStart=/usr/bin/npm run client:dev
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now habitica-mongodb
systemctl enable -q --now habitica
systemctl enable -q --now habitica-client
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
