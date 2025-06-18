#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/arunavo4/gitea-mirror

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

fetch_and_deploy_gh_release "gitea-mirror" "arunavo4/gitea-mirror"

msg_info "Installing gitea-mirror"
cd /opt/gitea-mirror
$STD bun run setup
$STD bun run build
msg_ok "Installed gitea-mirror"

msg_info "Creating Services"
JWT_SECRET=$(openssl rand -hex 32)
APP_VERSION=$(grep -o '"version": *"[^"]*"' package.json | cut -d'"' -f4)
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
Environment=NODE_ENV=production
Environment=HOST=0.0.0.0
Environment=PORT=4321
Environment=DATABASE_URL=file:/opt/gitea-mirror/data/gitea-mirror.db
Environment=JWT_SECRET=${JWT_SECRET}
Environment=npm_package_version=${APP_VERSION}
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
