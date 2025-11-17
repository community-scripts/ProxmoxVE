#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CrazyWolf13/domain-locker

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION="17" setup_postgresql
PG_DB_NAME="domainlocker_db" PG_DB_USER="domainlocker" setup_postgresql_db
NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "domain-locker" "Lissy93/domain-locker"

msg_info "Installing Modules (patience)"
cd /opt/domain-locker
$STD npm install
msg_ok "Installed Modules"

msg_info "Building Domain-Locker (a lot of patience)"
cat <<EOF >/opt/domain-locker.env
# Database connection
DL_PG_HOST=localhost
DL_PG_PORT=5432
DL_PG_USER=$PG_DB_USER
DL_PG_PASSWORD=$PG_DB_PASS
DL_PG_NAME=$PG_DB_NAME

# Build + Runtime
DL_ENV_TYPE=selfHosted
NITRO_PRESET=node_server
NODE_ENV=production
EOF
set -a
source /opt/domain-locker.env
set +a
$STD npm run build
msg_info "Built Domain-Locker"

msg_info "Building Database schema"
export PGPASSWORD="$DL_PG_PASSWORD"
$STD psql -h "$DL_PG_HOST" -p "$DL_PG_PORT" -U "$DL_PG_USER" -d "$DL_PG_NAME" -f "/opt/domain-locker/db/schema.sql"
msg_ok "Built Database schema"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/domain-locker.service
[Unit]
Description=Domain-Locker Service
After=network.target

[Service]
EnvironmentFile=/opt/domain-locker.env
WorkingDirectory=/opt/domain-locker
ExecStart=/opt/domain-locker/start.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl start --now -q domain-locker
msg_info "Created Service"

motd_ssh
customize
cleanup_lxc
