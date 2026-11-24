#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/activepieces/activepieces

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
  python3 \
  poppler-utils \
  redis-server
msg_ok "Installed Dependencies"

PG_VERSION="16" PG_MODULES="pgvector" setup_postgresql
PG_DB_NAME="activepieces" PG_DB_USER="activepieces" PG_DB_EXTENSIONS="vector" setup_postgresql_db

fetch_and_deploy_gh_release "activepieces" "activepieces/activepieces" "tarball"
NODE_VERSION="24" NODE_MODULE="$(jq -r '.packageManager' /opt/activepieces/package.json)" setup_nodejs
fetch_and_deploy_gh_release "deno" "denoland/deno" "prebuild" "v$(jq -r '.devDependencies.deno' /opt/activepieces/packages/server/engine/package.json)" "/usr/local/bin" "deno-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.zip"

msg_info "Building Activepieces"
cd /opt/activepieces
REDISMS_DISABLE_POSTINSTALL=1 $STD bun install --frozen-lockfile
$STD npx turbo run build --filter=web --filter=@activepieces/engine --filter=api --filter=worker
find dist/packages/web -name '*.map' -delete
rm -rf node_modules bun.lock packages/pieces/core packages/pieces/custom packages/web packages/cli packages/tests-e2e packages/ee
find packages/pieces/community -mindepth 1 -maxdepth 1 -type d ! -name slack ! -name square ! -name facebook-leads ! -name intercom ! -name microsoft-teams-bot -exec rm -rf {} +
node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json','utf8'));p.workspaces=p.workspaces.filter(w=>fs.existsSync(w.replace('/*','')));fs.writeFileSync('package.json',JSON.stringify(p,null,2))"
REDISMS_DISABLE_POSTINSTALL=1 $STD bun install --production
rm -rf ~/.bun/install/cache
msg_ok "Built Activepieces"

msg_info "Configuring Activepieces"
mkdir -p /opt/activepieces_data/cache
JWT_SECRET=$(openssl rand -hex 32)
cat <<EOF >/opt/activepieces_data/.env
NODE_ENV=production
AP_ENVIRONMENT=prod
AP_PORT=80
AP_FRONTEND_URL=http://${LOCAL_IP}
AP_API_KEY=$(openssl rand -hex 64)
AP_ENCRYPTION_KEY=$(openssl rand -hex 16)
AP_JWT_SECRET=${JWT_SECRET}
AP_WORKER_TOKEN=$(node -e "process.stdout.write(require('jsonwebtoken').sign({ id: require('crypto').randomUUID(), type: 'WORKER' }, process.argv[1], { expiresIn: '100y', keyid: '1', algorithm: 'HS256', issuer: 'activepieces' }))" "${JWT_SECRET}")
AP_POSTGRES_HOST=localhost
AP_POSTGRES_PORT=5432
AP_POSTGRES_DATABASE=activepieces
AP_POSTGRES_USERNAME=activepieces
AP_POSTGRES_PASSWORD=${PG_DB_PASS}
AP_REDIS_HOST=localhost
AP_REDIS_PORT=6379
AP_EXECUTION_MODE=UNSANDBOXED
AP_DENO_PATH=/usr/local/bin/deno
AP_CACHE_BASE_PATH=/opt/activepieces_data/cache
AP_CONFIG_PATH=/opt/activepieces_data
AP_TELEMETRY_ENABLED=false
EOF
chmod 600 /opt/activepieces_data/.env
msg_ok "Configured Activepieces"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/activepieces.service
[Unit]
Description=Activepieces
After=network.target postgresql.service redis-server.service
Wants=activepieces-worker.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/activepieces
EnvironmentFile=/opt/activepieces_data/.env
Environment=AP_CONTAINER_TYPE=APP
ExecStart=/usr/bin/node --enable-source-maps packages/server/api/dist/src/bootstrap.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/activepieces-worker.service
[Unit]
Description=Activepieces Worker
After=activepieces.service
PartOf=activepieces.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/activepieces
EnvironmentFile=/opt/activepieces_data/.env
ExecStart=/usr/bin/node --enable-source-maps packages/server/worker/dist/src/bootstrap.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now activepieces activepieces-worker
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
