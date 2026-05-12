#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mattogodoy/nametag

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION="16" setup_postgresql
PG_DB_NAME="nametag_db" PG_DB_USER="nametag" setup_postgresql_db
NODE_VERSION="20" setup_nodejs
fetch_and_deploy_gh_release "nametag" "mattogodoy/nametag" "tarball" "latest" "/opt/nametag"

msg_info "Setting up Application"
cd /opt/nametag
$STD npm ci
DATABASE_URL="postgresql://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}" $STD npx prisma generate
DATABASE_URL="postgresql://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}" $STD npx prisma migrate deploy
msg_ok "Set up Application"

msg_info "Configuring Nametag"
NEXTAUTH_SECRET=$(openssl rand -base64 32)
CRON_SECRET=$(openssl rand -base64 16)
mkdir -p /opt/nametag/data/photos
cat <<EOF >/opt/nametag/.env
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}
NEXTAUTH_URL=http://${LOCAL_IP}:3000
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
CRON_SECRET=${CRON_SECRET}
PHOTO_STORAGE_PATH=/opt/nametag/data/photos
NODE_ENV=production
EOF
msg_ok "Configured Nametag"

msg_info "Building Application"
cd /opt/nametag
set -a
source /opt/nametag/.env
set +a
$STD npm run build
cp -r /opt/nametag/.next/static /opt/nametag/.next/standalone/.next/static
cp -r /opt/nametag/public /opt/nametag/.next/standalone/public
msg_ok "Built Application"

msg_info "Running Production Seed"
cd /opt/nametag
$STD npx esbuild prisma/seed.production.ts --platform=node --format=cjs --outfile=prisma/seed.production.js --bundle --external:@prisma/client --external:pg --minify
$STD node prisma/seed.production.js
msg_ok "Ran Production Seed"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/nametag.service
[Unit]
Description=Nametag - Personal Relationships Manager
After=network.target postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/nametag
EnvironmentFile=/opt/nametag/.env
ExecStart=/usr/bin/node /opt/nametag/.next/standalone/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now nametag
msg_ok "Created Service"

msg_info "Setting up Cron Jobs"
cat <<EOF >/etc/cron.d/nametag
0 8 * * * root curl -sf -H "Authorization: Bearer ${CRON_SECRET}" http://127.0.0.1:3000/api/cron/send-reminders >/dev/null 2>&1
0 3 * * * root curl -sf -H "Authorization: Bearer ${CRON_SECRET}" http://127.0.0.1:3000/api/cron/purge-deleted >/dev/null 2>&1
EOF
chmod 644 /etc/cron.d/nametag
msg_ok "Set up Cron Jobs"

motd_ssh
customize
cleanup_lxc
