#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/jordan-dalby/ByteStash

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    sudo \
    curl \
    mc \
    gnupg
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Installing ByteStash"
JWT_SECRET=$(openssl rand -base64 32 | tr -d '/+=')
temp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/jordan-dalby/ByteStash/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/jordan-dalby/ByteStash/archive/refs/tags/v${RELEASE}.tar.gz" -O $temp_file
tar zxf $temp_file
mv ByteStash-${RELEASE} /opt/bytestash
cd /opt/bytestash/server
$STD npm install
cd /opt/bytestash/client
$STD npm install
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed ByteStash"

read -p "Do you want to allow registration of multiple accounts? [y/n]: " allowreg

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/bytestash-backend.service
[Unit]
Description=ByteStash Backend Service
After=network.target

[Service]
WorkingDirectory=/opt/bytestash/server
ExecStart=/usr/bin/node src/app.js
Restart=always
Environment=JWT_SECRET=$JWT_SECRET

[Install]
WantedBy=multi-user.target
EOF

if [[ "$allowreg" =~ ^[Yy]$ ]]; then
    sed -i '8i\Environment=ALLOW_NEW_ACCOUNTS=true' /etc/systemd/system/bytestash-backend.service
fi

cat <<EOF >/etc/systemd/system/bytestash-frontend.service
[Unit]
Description=ByteStash Frontend Service
After=network.target bytestash-backend.service

[Service]
WorkingDirectory=/opt/bytestash/client
ExecStart=/usr/bin/npx vite --host
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now bytestash-backend
systemctl enable -q --now bytestash-frontend
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
