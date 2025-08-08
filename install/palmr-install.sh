#!/usr/bin/env bash

# Copyright (c) 2025 Community Scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/kyantech/Palmr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "Palmr" "kyantech/Palmr" "tarball" "latest" "/opt/palmr"
PNPM="$(jq -r '.packageManager' /opt/palmr/package.json)" NODE_VERSION="20" NODE_MODULE="$PNPM" setup_nodejs

msg_info "Configuring palmr backend"
PALMR_DIR="/opt/palmr_data"
mkdir -p "$PALMR_DIR"
PALMR_DB="${PALMR_DIR}/palmr.db"
PALMR_KEY="$(openssl rand -hex 32)"
cd /opt/palmr/apps/server
sed -e 's/_ENCRYPTION=true/_ENCRYPTION=false/' \
  -e '/^# ENC/s/# //' \
  -e "s/ENCRYPTION_KEY=.*$/ENCRYPTION_KEY=$PALMR_KEY/" \
  -e "s|file:.*$|file:$PALMR_DB\"|" \
  -e '/db"$/a\# Uncomment below when using reverse proxy\
# SECURE_SITE=true' \
  .env.example >./.env
$STD pnpm install
$STD pnpm dlx prisma generate
$STD pnpm dlx prisma migrate deploy
$STD pnpm dlx prisma db push
$STD pnpm db:seed
$STD pnpm build
msg_ok "Configured palmr backend"

msg_info "Configuring palmr frontend"
cd /opt/palmr/apps/web
mv ./.env.example ./.env
export NODE_ENV=production
export NEXT_TELEMETRY_DISABLED=1
$STD pnpm install
$STD pnpm build
msg_ok "Configured palmr frontend"

msg_info "Creating service"
useradd -d "$PALMR_DIR" -M -s /usr/sbin/nologin -U palmr
chown -R palmr:palmr "$PALMR_DIR" /opt/palmr
cat <<EOF >/etc/systemd/system/palmr-backend.service
[Unit]
Description=palmr Backend Service
After=network.target

[Service]
Type=simple
User=palmr
Group=palmr
WorkingDirectory=/opt/palmr_data
ExecStart=/usr/bin/node /opt/palmr/apps/server/dist/server.js

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/palmr-frontend.service
[Unit]
Description=palmr Frontend Service
After=network.target palmr-backend.service

[Service]
Type=simple
User=palmr
Group=palmr
WorkingDirectory=/opt/palmr/apps/web
ExecStart=/usr/bin/pnpm start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now palmr-backend palmr-frontend
msg_ok "Created service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
