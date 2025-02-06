#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Snarkenfaugister
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pocket-id/pocket-id

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
  gpg \
  caddy \
  gcc
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

msg_info "Installing Golang"
set +o pipefail
temp_file=$(mktemp)
golang_tarball=$(curl -s https://go.dev/dl/ | grep -oP 'go[\d\.]+\.linux-amd64\.tar\.gz' | head -n 1)
wget -q https://golang.org/dl/"$golang_tarball" -O "$temp_file"
tar -C /usr/local -xzf "$temp_file"
ln -sf /usr/local/go/bin/go /usr/local/bin/go
rm -f "$temp_file"
set -o pipefail
msg_ok "Installed Golang"

read -r -p "What public URL do you want to use (e.g. pocketid.mydomain.com)? " public_url
msg_info "Setup Pocket ID"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/pocket-id/pocket-id/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/pocket-id/pocket-id/archive/refs/tags/v${RELEASE}.zip"
unzip -q v${RELEASE}.zip
mv pocket-id-${RELEASE}/ /opt/pocket-id

cd /opt/pocket-id/backend
cp .env.example .env
sed -i "s/PUBLIC_APP_URL=http:\/\/localhost/PUBLIC_APP_URL=https:\/\/${public_url}/" .env
cd cmd
CGO_ENABLED=1 
GOOS=linux
$STD go build -o ../pocket-id-backend

cd ../../frontend
cp .env.example .env
sed -i "s/PUBLIC_APP_URL=http:\/\/localhost/PUBLIC_APP_URL=https:\/\/${public_url}/" .env
$STD npm install
$STD npm run build

cd ..
cp reverse-proxy/Caddyfile /etc/caddy/Caddyfile
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Setup Pocket ID"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/pocketid-backend.service
[Unit]
Description=Pocket ID Backend
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/pocket-id/backend
EnvironmentFile=/opt/pocket-id/backend/.env
ExecStart=/opt/pocket-id/backend/pocket-id-backend
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/pocketid-frontend.service
[Unit]
Description=Pocket ID Frontend
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/pocket-id/frontend
EnvironmentFile=/opt/pocket-id/frontend/.env
ExecStart=/usr/bin/node build/index.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
msg_ok "Created Service"

msg_info "Starting Services"
systemctl enable -q --now pocketid-backend
systemctl enable -q --now pocketid-frontend
systemctl restart caddy
msg_ok "Started Services"

motd_ssh
customize

msg_info "Cleaning up"
rm -f /opt/v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
