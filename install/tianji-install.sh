#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/msgbyte/tianji

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  python3 \
  cmake \
  g++ \
  build-essential \
  git \
  ca-certificates
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="pnpm@$(curl -s https://raw.githubusercontent.com/msgbyte/tianji/master/package.json | jq -r '.packageManager | split("@")[1]')" setup_nodejs
PG_VERSION="16" setup_postgresql
PYTHON_VERSION="3.12" setup_uv

msg_info "Setting up PostgreSQL"
DB_NAME=tianji_db
DB_USER=tianji
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
TIANJI_SECRET="$(openssl rand -base64 32 | cut -c1-24)"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
$STD sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
$STD sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
{
  echo ""
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
  echo "Database Name: $DB_NAME"
  echo "Tianji Secret: $TIANJI_SECRET"
} >>~/tianji.creds
msg_ok "Set up PostgreSQL"

fetch_and_deploy_gh_release "tianji" "msgbyte/tianji"

msg_info "Setup Tianji"
cd /opt/tianji
$STD pnpm install --filter @tianji/client... --config.dedupe-peer-dependents=false --frozen-lockfile
$STD pnpm build:static
$STD pnpm install --filter @tianji/server... --config.dedupe-peer-dependents=false
mkdir -p ./src/server/public
cp -r ./geo ./src/server/public
$STD pnpm build:server
cat <<EOF >/opt/tianji/src/server/.env
DATABASE_URL="postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME?schema=public"
OPENAI_API_KEY=""
JWT_SECRET="$TIANJI_SECRET"
EOF
cd /opt/tianji/src/server
$STD pnpm db:migrate:apply
msg_ok "Setup Tianji"

msg_info "Setup AppRise"
$STD uv pip install apprise cryptography --system
msg_ok "Setup AppRise"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/tianji.service
[Unit]
Description=Tianji Server
After=network.target

[Service]
ExecStart=/usr/bin/node /opt/tianji/src/server/dist/src/server/main.js
WorkingDirectory=/opt/tianji/src/server
Restart=always
RestartSec=10

Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tianji
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/tianji/src/client
rm -rf /opt/tianji/website
rm -rf /opt/tianji/reporter
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
