#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/blinkospace/blinko

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="24" NODE_MODULE="bun" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_NAME="blinko" PG_DB_USER="blinko" setup_postgresql_db

fetch_and_deploy_gh_release "blinko" "blinkospace/blinko" "tarball"

msg_info "Building Blinko"
cd /opt/blinko
$STD bun install
$STD bunx prisma generate
$STD bun run build:web
$STD bun run build:seed
# The server resolves its web root as ../server/public and lute/vditor next to its own bundle
mv dist/public server/public
cp -r server/lute.min.js server/vditor dist/
msg_ok "Built Blinko"

msg_info "Configuring Blinko"
mkdir -p /opt/blinko_data/storage
# Blinko keeps uploads, the vector index and backups in .blinko under its working directory
ln -s /opt/blinko_data/storage /opt/blinko/.blinko
cat <<EOF >/opt/blinko_data/.env
NODE_ENV=production
DATABASE_URL=postgresql://blinko:${PG_DB_PASS}@localhost:5432/blinko
TRUST_PROXY=1
EOF
chmod 600 /opt/blinko_data/.env
msg_ok "Configured Blinko"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/blinko.service
[Unit]
Description=Blinko
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/blinko
EnvironmentFile=/opt/blinko_data/.env
ExecStartPre=/opt/blinko/node_modules/.bin/prisma migrate deploy
ExecStartPre=/usr/bin/node /opt/blinko/dist/seed.js
ExecStart=/usr/bin/node /opt/blinko/dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now blinko
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
