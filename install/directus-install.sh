#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://directus.com/

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

NODE_VERSION="22" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_NAME="directus" PG_DB_USER="directus" setup_postgresql_db

msg_info "Installing Directus"
mkdir -p /opt/directus/uploads /opt/directus/extensions
cd /opt/directus
$STD npm init -y
DIRECTUS_VERSION=$(get_latest_github_release "directus/directus")
$STD npm install --omit=dev "directus@${DIRECTUS_VERSION}"
cat <<EOF >~/.directus
${DIRECTUS_VERSION}
EOF
msg_ok "Installed Directus"

msg_info "Configuring Directus"
DIRECTUS_KEY=$(openssl rand -hex 32)
DIRECTUS_SECRET=$(openssl rand -hex 32)
DIRECTUS_ADMIN_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c16)
cat <<EOF >/opt/directus/.env
HOST="0.0.0.0"
PORT=8055
PUBLIC_URL="http://${LOCAL_IP}:8055"
KEY="${DIRECTUS_KEY}"
SECRET="${DIRECTUS_SECRET}"

DB_CLIENT="pg"
DB_HOST="127.0.0.1"
DB_PORT=5432
DB_DATABASE="${PG_DB_NAME}"
DB_USER="${PG_DB_USER}"
DB_PASSWORD="${PG_DB_PASS}"

ADMIN_EMAIL="admin@community-scripts.org"
ADMIN_PASSWORD="${DIRECTUS_ADMIN_PASSWORD}"

STORAGE_LOCATIONS="local"
STORAGE_LOCAL_DRIVER="local"
STORAGE_LOCAL_ROOT="/opt/directus/uploads"
EXTENSIONS_PATH="/opt/directus/extensions"
TELEMETRY=false
EOF
chmod 640 /opt/directus/.env
msg_ok "Configured Directus"

msg_info "Initializing Directus"
cd /opt/directus
$STD /opt/directus/node_modules/.bin/directus bootstrap
msg_ok "Initialized Directus"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/directus.service
[Unit]
Description=Directus
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/directus
EnvironmentFile=/opt/directus/.env
ExecStart=/opt/directus/node_modules/.bin/directus start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now directus
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
