#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/benzino77/tasmocompiler

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies. Patience"
$STD apt-get install -y \
  git \
  python3-venv
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs

msg_info "Setup Platformio"
curl -fsSL -o get-platformio.py https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py
$STD python3 get-platformio.py
msg_ok "Setup Platformio"

msg_info "Setup TasmoCompiler"
mkdir /tmp/Tasmota
RELEASE=$(curl -fsSL https://api.github.com/repos/benzino77/tasmocompiler/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/benzino77/tasmocompiler/archive/refs/tags/v${RELEASE}.tar.gz" -o "/tmp/v${RELEASE}.tar.gz"
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
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
