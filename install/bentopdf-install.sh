#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/alam00000/bentopdf

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="24" setup_nodejs
fetch_and_deploy_gh_release "bentopdf" "alam00000/bentopdf" "tarball" "latest" "/opt/bentopdf"

msg_info "Setup BentoPDF"
cd /opt/bentopdf
$STD npm ci --no-audit --no-fund
$STD npm install http-server -g
cp ./.env.example ./.env.production
export NODE_OPTIONS="--max-old-space-size=3072"
export SIMPLE_MODE=true
export VITE_USE_CDN=true
$STD npm run build:all
msg_ok "Setup BentoPDF"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/bentopdf.service
[Unit]
Description=BentoPDF Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/bentopdf/dist
ExecStart=/usr/bin/npx http-server -g -b -d false -r --no-dotfiles
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now bentopdf
msg_ok "Created & started service"

motd_ssh
customize
cleanup_lxc
