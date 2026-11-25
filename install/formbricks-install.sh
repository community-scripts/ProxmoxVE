#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/formbricks/formbricks

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y valkey-server
sed -i 's/^appendonly no/appendonly yes/' /etc/valkey/valkey.conf
systemctl restart valkey-server
msg_ok "Installed Dependencies"

PG_VERSION="18" PG_MODULES="pgvector" setup_postgresql
PG_DB_NAME="formbricks" PG_DB_USER="formbricks" PG_DB_EXTENSIONS="vector" setup_postgresql_db
# setup_postgresql_db keeps an already set PG_DB_PASS, so the SpiceDB role gets the same password
PG_DB_NAME="spicedb" PG_DB_USER="spicedb" setup_postgresql_db

fetch_and_deploy_gh_release "spicedb" "authzed/spicedb" "binary"
fetch_and_deploy_gh_release "formbricks" "formbricks/formbricks" "tarball"
NODE_VERSION="24" NODE_MODULE="pnpm@$(jq -r '.packageManager | split("@")[1]' /opt/formbricks/package.json)" setup_nodejs

msg_info "Building Formbricks (Patience)"
cd /opt/formbricks
sed -i "s/\"version\": \"0.0.0\"/\"version\": \"$(cat ~/.formbricks)\"/" apps/web/package.json
sed -i 's/^const nextConfig = {$/&\n  typescript: { ignoreBuildErrors: true },/' apps/web/next.config.mjs
touch apps/web/.env
$STD pnpm install --ignore-scripts --frozen-lockfile
$STD sh apps/web/scripts/docker/read-secrets.sh pnpm build --filter=@formbricks/web...
cp -r apps/web/.next/static apps/web/.next/standalone/apps/web/.next/
cp -r apps/web/public apps/web/.next/standalone/apps/web/
msg_ok "Built Formbricks"

msg_info "Configuring Formbricks"
mkdir -p /opt/formbricks_data
AUTHZED_TOKEN=$(openssl rand -hex 32)
cat <<EOF >/opt/formbricks_data/.env
NODE_ENV=production
WEBAPP_URL=http://${LOCAL_IP}:3000
NEXTAUTH_URL=http://${LOCAL_IP}:3000
NEXTAUTH_SECRET=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
CRON_SECRET=$(openssl rand -hex 32)
DATABASE_URL=postgresql://formbricks:${PG_DB_PASS}@localhost:5432/formbricks?schema=public
REDIS_URL=redis://localhost:6379
AUTHZED_ENABLED=true
AUTHZED_ENDPOINT=127.0.0.1:50051
AUTHZED_TOKEN=${AUTHZED_TOKEN}
AUTHZED_SYSTEM_KEY=formbricks
AUTHZED_INSECURE=true
AUTHZED_CONSISTENCY=fully_consistent
HUB_API_URL=http://127.0.0.1:8080
HUB_API_KEY=$(openssl rand -hex 32)
CUBEJS_API_URL=http://127.0.0.1:4000
CUBEJS_API_SECRET=$(openssl rand -hex 32)
EMAIL_VERIFICATION_DISABLED=1
PASSWORD_RESET_DISABLED=1
TELEMETRY_DISABLED=1
EOF
cat <<EOF >/opt/formbricks_data/spicedb.env
SPICEDB_DATASTORE_ENGINE=postgres
SPICEDB_DATASTORE_CONN_URI=postgres://spicedb:${PG_DB_PASS}@localhost:5432/spicedb?sslmode=disable
SPICEDB_GRPC_PRESHARED_KEY=${AUTHZED_TOKEN}
SPICEDB_GRPC_ADDR=127.0.0.1:50051
SPICEDB_METRICS_ADDR=127.0.0.1:9090
SPICEDB_TELEMETRY_ENDPOINT=
SPICEDB_LOG_LEVEL=warn
EOF
chmod 600 /opt/formbricks_data/.env /opt/formbricks_data/spicedb.env
msg_ok "Configured Formbricks"

msg_info "Setting up SpiceDB"
set -a && source /opt/formbricks_data/spicedb.env && set +a
$STD spicedb datastore migrate head
cat <<EOF >/etc/systemd/system/spicedb.service
[Unit]
Description=SpiceDB
After=network.target postgresql.service

[Service]
Type=simple
User=root
EnvironmentFile=/opt/formbricks_data/spicedb.env
ExecStart=/usr/bin/spicedb serve
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now spicedb
msg_ok "Set up SpiceDB"

msg_info "Migrating Formbricks Database"
set -a && source /opt/formbricks_data/.env && set +a
$STD node packages/database/dist/scripts/apply-migrations.js
$STD node apps/web/dist/authzed-cli/index.mjs upgrade prepare
msg_ok "Migrated Formbricks Database"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/formbricks.service
[Unit]
Description=Formbricks
After=network.target postgresql.service valkey-server.service spicedb.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/formbricks/apps/web/.next/standalone
EnvironmentFile=/opt/formbricks_data/.env
ExecStart=/usr/bin/node apps/web/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now formbricks
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
