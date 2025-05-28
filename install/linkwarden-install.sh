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
$STD apt-get install -y \
  make \
  build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn@latest" install_node_and_modules
PG_VERSION="16" install_postgresql
RUST_CRATES="monolith" install_rust_and_crates

msg_info "Setting up PostgreSQL DB"
DB_NAME=linkwardendb
DB_USER=linkwarden
DB_PASS="$(openssl rand -base64 18 | tr -d '/' | cut -c1-13)"
SECRET_KEY="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC';"
{
  echo "Linkwarden-Credentials"
  echo "Linkwarden Database User: $DB_USER"
  echo "Linkwarden Database Password: $DB_PASS"
  echo "Linkwarden Database Name: $DB_NAME"
  echo "Linkwarden Secret: $SECRET_KEY"
} >>~/linkwarden.creds
msg_ok "Set up PostgreSQL DB"

read -r -p "${TAB3}Would you like to add Adminer? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  install_adminer
fi

msg_info "Installing Linkwarden (Patience)"
fetch_and_deploy_gh_release "linkwarden/linkwarden"
cd /opt/linkwarden
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

msg_info "Cleaning up"
rm -rf ~/.cargo/registry ~/.cargo/git ~/.cargo/.package-cache ~/.rustup
rm -rf /root/.cache/yarn
rm -rf /opt/linkwarden/.next/cache
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
