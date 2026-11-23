#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/3xpyth0n/ideon

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="26" setup_nodejs
PG_VERSION="18" setup_postgresql
PG_DB_NAME="ideon" PG_DB_USER="ideon" setup_postgresql_db
$STD sudo -u postgres psql -c "ALTER ROLE ideon BYPASSRLS;"

fetch_and_deploy_gh_release "ideon" "3xpyth0n/ideon" "tarball"

msg_info "Building Ideon"
cd /opt/ideon
$STD npm ci
NEXT_TELEMETRY_DISABLED=1 NODE_ENV=production IS_NEXT_BUILD=1 $STD npm run build
$STD npm prune --omit=dev
rm -rf /opt/ideon/.next/cache ~/.npm
msg_ok "Built Ideon"

msg_info "Configuring Ideon"
mkdir -p /opt/ideon_data/storage/{avatars,uploads,yjs}
cat <<EOF >/opt/ideon_data/.env
NODE_ENV=production
APP_PORT=3000
APP_URL=http://${LOCAL_IP}:3000
AUTH_TRUST_HOST=true
TIMEZONE=UTC
LOG_LEVEL=info
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ideon
DB_USER=ideon
DB_PASS=${PG_DB_PASS}
SECRET_KEY=$(openssl rand -hex 32)
SMTP_FROM_EMAIL=
SMTP_FROM_NAME=
SMTP_HOST=
SMTP_USER=
SMTP_PASSWORD=
SMTP_PORT=
SMTP_USE_TLS=true
EOF
chmod 600 /opt/ideon_data/.env
msg_ok "Configured Ideon"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ideon.service
[Unit]
Description=Ideon
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ideon
EnvironmentFile=/opt/ideon_data/.env
ExecStart=/usr/bin/node dist/server.cjs
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ideon
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
