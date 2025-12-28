#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://linkwarden.app/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  make \
  build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs
PG_VERSION="16" setup_postgresql
RUST_CRATES="monolith" setup_rust

msg_info "Setting up PostgreSQL DB"
PG_DB_NAME="linkwardendb"
PG_DB_USER="linkwarden"
PG_DB_PASS="$(openssl rand -base64 18 | tr -d '/' | cut -c1-13)"
PG_DB_CREDS_FILE="${HOME}/linkwarden.creds"
SECRET_KEY="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)"
# Use helper to create DB and user
PG_DB_NAME="$PG_DB_NAME" PG_DB_USER="$PG_DB_USER" PG_DB_PASS="$PG_DB_PASS" PG_DB_CREDS_FILE="$PG_DB_CREDS_FILE" setup_postgresql_db
msg_ok "Set up PostgreSQL DB"

read -r -p "${TAB3}Would you like to add Adminer? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  setup_adminer
fi

msg_info "Installing Linkwarden (Patience)"
fetch_and_deploy_gh_release "linkwarden" "linkwarden/linkwarden"
cd /opt/linkwarden
if command -v corepack >/dev/null 2>&1; then
  $STD corepack enable
  $STD corepack prepare yarn@4.12.0 --activate || true
fi
$STD yarn
$STD npx playwright install-deps
$STD yarn playwright install
IP=$(hostname -I | awk '{print $1}')
cat <<EOF >/opt/linkwarden/.env
NEXTAUTH_SECRET=${SECRET_KEY}
NEXTAUTH_URL=http://${IP}:3000
DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}
EOF
$STD yarn prisma:generate
$STD yarn web:build
$STD yarn prisma:deploy
rm -rf ~/.cargo/registry ~/.cargo/git ~/.cargo/.package-cache
rm -rf /root/.cache/yarn
rm -rf /opt/linkwarden/.next/cache
msg_ok "Installed Linkwarden"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/linkwarden.service
[Unit]
Description=Linkwarden Service
After=network.target

[Service]
Type=exec
Environment=PATH=$PATH
WorkingDirectory=/opt/linkwarden
ExecStart=/usr/bin/yarn concurrently:start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now linkwarden
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
