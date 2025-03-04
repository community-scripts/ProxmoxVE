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
    curl \
    sudo \
    mc \
    libkrb5-dev \
    gnupg \
    build-essential \
    git
wget -q http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
$STD dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Setup Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Setup Node.js"

msg_info "Setup ${APPLICATION}"
temp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/HabitRPG/habitica/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/HabitRPG/habitica/archive/refs/tags/v${RELEASE}.tar.gz" -O $temp_file
tar zxf $temp_file
mv habitica-${RELEASE}/ /opt/habitica
cd /opt/habitica
$STD npm i
cp config.json.example config.json
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
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
rm -f $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
