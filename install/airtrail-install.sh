#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/johanohly/AirTrail

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs

msg_info "Installing Bun"
export BUN_INSTALL="/root/.bun"
curl -fsSL https://bun.sh/install | $STD bash
ln -sf /root/.bun/bin/bun /usr/local/bin/bun
ln -sf /root/.bun/bin/bunx /usr/local/bin/bunx
msg_ok "Installed Bun"

PG_VERSION="16" setup_postgresql
PG_DB_NAME="airtrail" PG_DB_USER="airtrail" setup_postgresql_db

fetch_and_deploy_gh_release "airtrail" "johanohly/AirTrail" "tarball" "latest" "/opt/airtrail"

msg_info "Configuring AirTrail"
mkdir -p /opt/airtrail/uploads
cat <<EOF >/opt/airtrail/.env
NODE_ENV=production
DB_URL=postgres://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}
ORIGIN=http://${LOCAL_IP}:3000
BODY_SIZE_LIMIT=20M
UPLOAD_LOCATION=/opt/airtrail/uploads
EOF
msg_ok "Configured AirTrail"

msg_info "Building AirTrail (Patience)"
cd /opt/airtrail
$STD bun install --frozen-lockfile
export NODE_ENV=production
$STD bun run build
$STD bun install --frozen-lockfile --production
msg_ok "Built AirTrail"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/airtrail.service
[Unit]
Description=AirTrail
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/airtrail
EnvironmentFile=/opt/airtrail/.env
ExecStartPre=/usr/bin/node /opt/airtrail/docker/migrate.js
ExecStart=/usr/bin/node /opt/airtrail/build
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now airtrail
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
