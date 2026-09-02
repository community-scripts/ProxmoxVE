#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/kikootwo/ReadMeABook

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
  openssl \
  redis-server
systemctl enable -q --now redis-server
msg_ok "Installed Dependencies"

setup_ffmpeg
PG_VERSION="17" setup_postgresql
PG_DB_NAME="readmeabook" PG_DB_USER="readmeabook" setup_postgresql_db
NODE_VERSION="20" setup_nodejs

fetch_and_deploy_gh_release "readmeabook" "kikootwo/ReadMeABook" "tarball"

msg_info "Configuring ReadMeABook"
mkdir -p /opt/readmeabook_data/{config,cache,downloads}
cat <<EOF >/opt/readmeabook/.env
NODE_ENV=production
PORT=3030
NEXT_TELEMETRY_DISABLED=1
CONFIG_ENCRYPTION_KEY=$(openssl rand -base64 32)
DATABASE_URL=postgresql://readmeabook:${PG_DB_PASS}@127.0.0.1:5432/readmeabook?schema=public
REDIS_URL=redis://127.0.0.1:6379
NEXTAUTH_SECRET=$(openssl rand -hex 32)
CONFIG_DIR=/opt/readmeabook_data/config
CACHE_DIR=/opt/readmeabook_data/cache
EOF
chmod 600 /opt/readmeabook/.env
msg_ok "Configured ReadMeABook"

msg_info "Building ReadMeABook (Patience)"
cd /opt/readmeabook
$STD npm ci
set -a
source /opt/readmeabook/.env
set +a
$STD npx prisma generate
$STD npx prisma db push --skip-generate --accept-data-loss
$STD npm run build
if [[ -f /opt/readmeabook/.next/standalone/server.js ]]; then
  cp -r /opt/readmeabook/.next/static /opt/readmeabook/.next/standalone/.next/static
  [[ -d /opt/readmeabook/public ]] && cp -r /opt/readmeabook/public /opt/readmeabook/.next/standalone/public
  START_CMD="/usr/bin/node /opt/readmeabook/.next/standalone/server.js"
else
  START_CMD="/usr/bin/npm run start"
fi
msg_ok "Built ReadMeABook"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/readmeabook.service
[Unit]
Description=ReadMeABook
Wants=network-online.target
After=network-online.target postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/readmeabook
EnvironmentFile=/opt/readmeabook/.env
ExecStart=${START_CMD}
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now readmeabook
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
