#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ajnart/homarr

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  sudo \
  mc \
  curl \
  ca-certificates \
  gnupg \
  make \
  g++ \
  build-essential
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js/Yarn"
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g yarn
msg_ok "Installed Node.js/Yarn"

msg_info "Installing Homarr (Patience)"
RELEASE=$(curl -s https://api.github.com/repos/ajnart/homarr/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/ajnart/homarr/archive/refs/tags/v${RELEASE}.zip"
unzip -q v${RELEASE}.zip
rm -rf v${RELEASE}.zip
mv homarr-${RELEASE} /opt/homarr
cat <<EOF >/opt/homarr/.env
DATABASE_URL="file:./database/db.sqlite"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="$(openssl rand -base64 32)"
NEXT_PUBLIC_DISABLE_ANALYTICS="true"
DEFAULT_COLOR_SCHEME="dark"
EOF
cd /opt/homarr
$STD yarn install
$STD yarn build
$STD yarn db:migrate
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Homarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/homarr.service
[Unit]
Description=Homarr Service
After=network.target

[Service]
Type=exec
WorkingDirectory=/opt/homarr
EnvironmentFile=-/opt/homarr/.env
ExecStart=/usr/bin/yarn start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now homarr.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
