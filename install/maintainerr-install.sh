#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: caroipdev
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

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
        wget \
        mc \
        gpg \
        python3 \
        make \
        g++

msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install --global yarn

$STD corepack enable
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
msg_ok "Installed Node.js"

msg_info "Installing Maintainerr"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/jorenn92/maintainerr/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q https://github.com/jorenn92/maintainerr/archive/refs/tags/v${RELEASE}.zip
$STD unzip -q v${RELEASE}.zip
rm -rf "/opt/v${RELEASE}.zip"
$STD mkdir app
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
cd /opt/Maintainerr-${RELEASE}
$STD corepack install
msg_ok "Installed Maintainerr"

msg_info "Building Maintainerr"
$STD yarn --immutable --network-timeout 99999999

# linting is not necessary
$STD rm ./server/.eslintrc.js
$STD rm ./ui/.eslintrc.json

$STD yarn build:server

cat >> ./ui/.env <<EOF
NEXT_PUBLIC_BASE_PATH=/__PATH_PREFIX__
EOF

sed -i "s,basePath: '',basePath: '/__PATH_PREFIX__',g" ./ui/next.config.js
$STD yarn build:ui


# Data dir
mkdir -m 777 /opt/data
mkdir -m 777 /opt/data/logs
# chown -R node:node /opt/data

# Migrate DB
$STD yarn migration:run
mv ./data /opt/data

# copy standalone UI 
mv ./ui/.next/standalone/ui/ ./standalone-ui/
mv ./ui/.next/standalone/ ./standalone-ui/
mv ./ui/.next/static ./standalone-ui/.next/static
mv ./ui/public ./standalone-ui/public
rm -rf ./ui
mv ./standalone-ui ./ui

# Copy standalone server
mv ./server/dist ./standalone-server
rm -rf ./server
mv ./standalone-server ./server

rm -rf node_modules .yarn

yarn workspaces focus --production

rm -rf .yarn
rm -rf /opt/yarn-*

mv /opt/Maintainerr-${RELEASE}/* /opt/app/
rm -rf /opt/Maintainerr-${RELEASE}

$STD cd /opt/app

msg_ok "Built Maintainerr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/maintainerr-server.service
[Unit]
Description=Maintainerr Server
After=network.target

[Service]
ExecStart=/usr/bin/yarn node /opt/app/server/main.js
Restart=always
RestartSec=5
StartLimitBurst=100
StartLimitInterval=0
Environment=NODE_ENV=production
Environment=VERSION_TAG=stable
Environment=npm_package_version=${RELEASE}
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/maintainerr.service
[Unit]
Description=Maintainerr
After=network.target

[Service]
ExecStart=/usr/bin/yarn node /opt/app/ui/server.js
Restart=always
RestartSec=5
StartLimitBurst=100
StartLimitInterval=0
Environment=PORT=6246
Environment=HOSTNAME=0.0.0.0
Environment=NODE_ENV=production
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now maintainerr-server.service
systemctl enable -q --now maintainerr.service
msg_ok "Created Service"

# customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
