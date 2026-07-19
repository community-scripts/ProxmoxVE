#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/liketrek/TREK

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  libkitinerary-bin
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs
fetch_and_deploy_gh_release "trek" "liketrek/TREK" "tarball"

msg_info "Setup TREK"
cd /opt/trek
$STD npm ci
$STD npm run build --workspace=shared
$STD npm run build --workspace=client
$STD npm run build --workspace=server
msg_ok "Setup TREK"

msg_info "Setting up TREK Workspace"
rm -rf /opt/trek/server/public
mkdir -p /opt/trek/server/public
cp -a /opt/trek/client/dist/. /opt/trek/server/public/
if [[ -d /opt/trek/client/public/fonts ]]; then
  mkdir -p /opt/trek/server/public/fonts
  cp -a /opt/trek/client/public/fonts/. /opt/trek/server/public/fonts/
fi
mkdir -p \
  /opt/trek/data/logs \
  /opt/trek/uploads/files \
  /opt/trek/uploads/covers \
  /opt/trek/uploads/avatars \
  /opt/trek/uploads/photos
rm -rf /opt/trek/server/data
rm -rf /opt/trek/server/uploads
ln -s /opt/trek/data /opt/trek/server/data
ln -s /opt/trek/uploads /opt/trek/server/uploads
cd /opt/trek
$STD npm prune --omit=dev
msg_ok "Set up TREK Workspace"

msg_info "Configuring TREK"
ENCRYPTION_KEY=$(openssl rand -hex 32)
ADMIN_EMAIL="admin@trek.local"
ADMIN_PASSWORD=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | head -c 16)
cat <<EOF >/opt/trek/server/.env
NODE_ENV=production
HOST=0.0.0.0
PORT=3000
ENCRYPTION_KEY=${ENCRYPTION_KEY}
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
TZ=UTC
LOG_LEVEL=info
DEFAULT_LANGUAGE=en
ALLOWED_ORIGINS=
COOKIE_SECURE=false
FORCE_HTTPS=false
TRUST_PROXY=1
EOF
chmod 600 /opt/trek/server/.env
msg_ok "Configured TREK"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/trek.service
[Unit]
Description=TREK Travel Planner
Documentation=https://github.com/liketrek/TREK
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/trek/server
EnvironmentFile=/opt/trek/server/.env
Environment=XDG_CACHE_HOME=/tmp/trek-kf6-cache
Environment=QT_QPA_PLATFORM=offscreen
ExecStart=/usr/bin/node --require tsconfig-paths/register dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now trek
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
