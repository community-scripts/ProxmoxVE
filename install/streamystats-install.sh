#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fredrikburmester/streamystats

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y unzip
msg_ok "Installed Dependencies"

PG_VERSION="17" PG_MODULES="pgvector" setup_postgresql
PG_DB_NAME="streamystats" PG_DB_USER="streamystats" PG_DB_EXTENSIONS="vector,pg_trgm,uuid-ossp" setup_postgresql_db

msg_info "Installing Bun"
export BUN_INSTALL="/root/.bun"
curl -fsSL https://bun.sh/install | $STD bash
ln -sf /root/.bun/bin/bun /usr/local/bin/bun
ln -sf /root/.bun/bin/bunx /usr/local/bin/bunx
msg_ok "Installed Bun"

fetch_and_deploy_gh_release "streamystats" "fredrikburmester/streamystats" "tarball"

msg_info "Building Streamystats"
cd /opt/streamystats
$STD bun install --frozen-lockfile
NEXT_TELEMETRY_DISABLED=1 NEXT_PUBLIC_VERSION="v$(cat ~/.streamystats)" $STD bun run build
msg_ok "Built Streamystats"

msg_info "Configuring Streamystats"
mkdir -p /opt/streamystats_data
cat <<EOF >/opt/streamystats_data/.env
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
DATABASE_URL=postgresql://streamystats:${PG_DB_PASS}@127.0.0.1:5432/streamystats
JOB_SERVER_URL=http://127.0.0.1:3005
NEXTJS_URL=http://127.0.0.1:3000
SESSION_SECRET=$(openssl rand -hex 64)
NEXT_SERVER_ACTIONS_ENCRYPTION_KEY=$(openssl rand -base64 32)
EOF
chmod 600 /opt/streamystats_data/.env
msg_ok "Configured Streamystats"

msg_info "Migrating Streamystats Database"
$STD bun --env-file=/opt/streamystats_data/.env run db:migrate
msg_ok "Migrated Streamystats Database"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/streamystats-job-server.service
[Unit]
Description=Streamystats Job Server
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/streamystats/apps/job-server
EnvironmentFile=/opt/streamystats_data/.env
Environment=HOST=127.0.0.1
Environment=PORT=3005
ExecStart=/usr/local/bin/bun run start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/streamystats-nextjs-app.service
[Unit]
Description=Streamystats Web
After=network.target streamystats-job-server.service
Wants=streamystats-job-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/streamystats/apps/nextjs-app
EnvironmentFile=/opt/streamystats_data/.env
Environment=PORT=3000
ExecStart=/usr/local/bin/bun run start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now streamystats-job-server streamystats-nextjs-app
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
