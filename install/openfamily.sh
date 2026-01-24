#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: NexaFlowFrance
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/NexaFlowFrance/OpenFamily

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  git \
  libcap2-bin \
  openssl
msg_ok "Installed Dependencies"

NODE_VERSION="20" NODE_MODULE="pnpm@latest" setup_nodejs
PG_VERSION="17" setup_postgresql

msg_info "Creating PostgreSQL Database"
PG_DB_NAME="openfamily_db"
PG_DB_USER="openfamily"
PG_DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)"

sudo -u postgres psql -c "CREATE ROLE ${PG_DB_USER} WITH LOGIN PASSWORD '${PG_DB_PASS}';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE ${PG_DB_NAME} WITH OWNER ${PG_DB_USER} ENCODING 'UTF8' TEMPLATE template0;" 2>/dev/null || true
$STD sudo -u postgres psql -c "ALTER ROLE ${PG_DB_USER} SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE ${PG_DB_USER} SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE ${PG_DB_USER} SET timezone TO 'UTC';"
msg_ok "Created PostgreSQL Database"

msg_info "Downloading OpenFamily from GitHub"
RELEASE=$(curl -fsSL https://api.github.com/repos/NexaFlowFrance/OpenFamily/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
$STD git clone --depth=1 --branch="${RELEASE}" https://github.com/NexaFlowFrance/OpenFamily.git /opt/openfamily
echo "${RELEASE}" >/opt/openfamily_version.txt
msg_ok "Downloaded OpenFamily ${RELEASE}"

msg_info "Configuring OpenFamily"
SESSION_SECRET="$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c32)"

cat <<EOF >/opt/openfamily/server/.env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=${PG_DB_NAME}
DB_USER=${PG_DB_USER}
DB_PASSWORD=${PG_DB_PASS}

SESSION_SECRET=${SESSION_SECRET}

NODE_ENV=production
PORT=3000
HOST=${LOCAL_IP}
EOF

cat <<EOF >/root/openfamily.creds
OpenFamily Credentials
======================
Database: ${PG_DB_NAME}
User: ${PG_DB_USER}
Password: ${PG_DB_PASS}
Session Secret: ${SESSION_SECRET}

Access: http://${LOCAL_IP}:3000
EOF
msg_ok "Configured OpenFamily"

msg_info "Installing Client Dependencies (Patience)"
cd /opt/openfamily/client
$STD pnpm install
msg_ok "Client dependencies installed"

msg_info "Building Client (Patience)"
$STD pnpm build
msg_ok "Client built"

msg_info "Installing Server Dependencies"
cd /opt/openfamily/server
$STD pnpm install
msg_ok "Server dependencies installed"

msg_info "Building Server (Patience)"
cd /opt/openfamily/server
$STD pnpm build
msg_ok "Server built"

msg_info "Initializing Database"
if [ -f /opt/openfamily/schema.sql ]; then
  PGPASSWORD=${PG_DB_PASS} psql -U ${PG_DB_USER} -d ${PG_DB_NAME} -h localhost -f /opt/openfamily/schema.sql >/dev/null 2>&1 || true
fi
msg_ok "Database initialized"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openfamily.service
[Unit]
Description=OpenFamily - Family Organization Platform
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/openfamily
Environment=NODE_ENV=production
EnvironmentFile=/opt/openfamily/server/.env
ExecStart=/usr/bin/node /opt/openfamily/dist/index.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now openfamily
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc

