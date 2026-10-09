#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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
$STD apt install -y \
  git \
  python3-venv
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs

msg_info "Setup Platformio"
curl -fsSL -o get-platformio.py https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py
$STD python3 get-platformio.py
msg_ok "Setup Platformio"

fetch_and_deploy_gh_release "tasmocompiler" "benzino77/tasmocompiler" "tarball"

msg_info "Setup TasmoCompiler"
mkdir /tmp/Tasmota
cd /opt/tasmocompiler
$STD yarn install
export NODE_OPTIONS=--openssl-legacy-provider
$STD npm i
$STD yarn build
mkdir -p /usr/local/bin
ln -s ~/.platformio/penv/bin/platformio /usr/local/bin/platformio
ln -s ~/.platformio/penv/bin/pio /usr/local/bin/pio
ln -s ~/.platformio/penv/bin/piodebuggdb /usr/local/bin/piodebuggdb
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
cleanup_lxc
