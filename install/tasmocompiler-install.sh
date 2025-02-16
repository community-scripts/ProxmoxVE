#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/benzino77/tasmocompiler

# Import Functions und Setup
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies. Patience"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  gnupg \
  git
msg_ok "Installed Dependencies"

msg_info "Setup Python3"
$STD apt-get install -y python3-venv
msg_ok "Setup Python3"

msg_info "Setup Node.js & yarn"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g yarn
msg_ok "Setup Node.js & yarn"

msg_info "Setup Platformio"
curl -fsSL -o get-platformio.py https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py
$STD python3 get-platformio.py
msg_ok "Setup Platformio"

msg_info "Setup TasmoCompiler"
mkdir /tmp/Tasmota
RELEASE=$(curl -s https://api.github.com/repos/benzino77/tasmocompiler/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q https://github.com/benzino77/tasmocompiler/archive/refs/tags/v${RELEASE}.tar.gz -O /tmp/v${RELEASE}.tar.gz
cd /tmp
tar xzf /tmp/v${RELEASE}.tar.gz
mv tasmocompiler-${RELEASE}/ /opt/tasmocompiler/
cd /opt/tasmocompiler
$STD yarn install
export NODE_OPTIONS=--openssl-legacy-provider
$STD npm i
$STD yarn build
mkdir -p /usr/local/bin
ln -s ~/.platformio/penv/bin/platformio /usr/local/bin/platformio
ln -s ~/.platformio/penv/bin/pio /usr/local/bin/pio
ln -s ~/.platformio/penv/bin/piodebuggdb /usr/local/bin/piodebuggdb
echo "${RELEASE}" >"/opt/tasmocompiler_version.txt"
msg_ok "Setup TasmoCompiler"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/tasmocompiler.service
[Unit]
Description=TasmoCompiler Service
After=multi-user.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/node /opt/tasmocompiler/server/app.js

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tasmocompiler
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f /tmp/v${RELEASE}.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"