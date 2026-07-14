#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ulsklyc/yuvomi

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  python3 \
  make \
  g++ \
  libsqlcipher-dev
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "yuvomi" "ulsklyc/yuvomi" "tarball"

msg_info "Installing Node.js Dependencies"
cd /opt/yuvomi
$STD npm ci --omit=dev
msg_ok "Installed Node.js Dependencies"

msg_info "Configuring Yuvomi"
mkdir -p /opt/yuvomi/data /opt/yuvomi/backups
SESSION_SECRET=$(openssl rand -hex 32)
DB_ENCRYPT_KEY=$(openssl rand -hex 32)
cat <<EOF >/opt/yuvomi/.env
PORT=3000
NODE_ENV=production
DB_PATH=/opt/yuvomi/data/yuvomi.db
DB_ENCRYPTION_KEY=${DB_ENCRYPT_KEY}
SESSION_SECRET=${SESSION_SECRET}
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_ATTEMPTS=5
RATE_LIMIT_BLOCK_DURATION_MS=900000
EOF
msg_ok "Configured Yuvomi"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/yuvomi.service
[Unit]
Description=Yuvomi Family Planner
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/yuvomi
EnvironmentFile=/opt/yuvomi/.env
ExecStart=/usr/bin/node server/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now yuvomi
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
