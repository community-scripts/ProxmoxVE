#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/RayLabsHQ/gitea-mirror

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt-get install -y \
  build-essential \
  openssl \
  sqlite3 \
  unzip
msg_ok "Installed Dependencies"

msg_info "Installing Bun"
export BUN_INSTALL=/opt/bun
curl -fsSL https://bun.sh/install | $STD bash
ln -sf /opt/bun/bin/bun /usr/local/bin/bun
ln -sf /opt/bun/bin/bun /usr/local/bin/bunx
msg_ok "Installed Bun"

fetch_and_deploy_gh_release "gitea-mirror" "RayLabsHQ/gitea-mirror"

msg_info "Installing gitea-mirror"
cd /opt/gitea-mirror
$STD bun run setup
$STD bun run build
msg_ok "Installed gitea-mirror"

msg_info "Creating Services"
APP_SECRET=$(openssl rand -base64 32)
APP_VERSION=$(grep -o '"version": *"[^"]*"' package.json | cut -d'"' -f4)
HOST_IP=$(hostname -I | awk '{print $1}')
cat <<EOF >/opt/gitea-mirror.env
# See here for config options: https://github.com/RayLabsHQ/gitea-mirror/blob/main/docs/ENVIRONMENT_VARIABLES.md
NODE_ENV=production
HOST=0.0.0.0
PORT=4321
DATABASE_URL=sqlite://data/gitea-mirror.db
BETTER_AUTH_URL=http://${HOST_IP}:4321
BETTER_AUTH_SECRET=${APP_SECRET}
npm_package_version=${APP_VERSION}
EOF

cat <<EOF >/etc/systemd/system/gitea-mirror.service
[Unit]
Description=Gitea Mirror
After=network.target
[Service]
Type=simple
WorkingDirectory=/opt/gitea-mirror
ExecStart=/usr/local/bin/bun dist/server/entry.mjs
Restart=on-failure
RestartSec=10
EnvironmentFile=/opt/gitea-mirror.env
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gitea-mirror
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
