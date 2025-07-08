#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dotnetfactory/fluid-calendar

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y zip
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
NODE_VERSION="20" setup_nodejs

msg_info "Setting up Postgresql Database"
DB_NAME="fluiddb"
DB_USER="fluiduser"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)"
NEXTAUTH_SECRET="$(openssl rand -base64 44 | tr -dc 'a-zA-Z0-9' | cut -c1-32)"
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME to $DB_USER;"
$STD sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
{
  echo "${APPLICATION} Credentials"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
  echo "Database Name: $DB_NAME"
  echo "NextAuth Secret: $NEXTAUTH_SECRET"
} >>~/$APPLICATION.creds
msg_ok "Set up Postgresql Database"

fetch_and_deploy_gh_release "fluid-calendar" "dotnetfactory/fluid-calendar"

msg_info "Configuring ${APPLICATION}"
cat <<EOF >/opt/fluid-calendar/.env
DATABASE_URL="postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}"

# Change the URL below to your external URL
NEXTAUTH_URL="http://localhost:3000"
NEXT_PUBLIC_APP_URL="http://localhost:3000"
NEXTAUTH_SECRET="${NEXTAUTH_SECRET}"
NEXT_PUBLIC_SITE_URL="http://localhost:3000"

NEXT_PUBLIC_ENABLE_SAAS_FEATURES=false

RESEND_API_KEY=
RESEND_EMAIL=
EOF
export NEXT_TELEMETRY_DISABLED=1
cd /opt/fluid-calendar
$STD npm install --legacy-peer-deps
$STD npm run prisma:generate
$STD npx prisma migrate deploy
$STD npm run build:os
msg_ok "Configuring ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/fluid-calendar.service
[Unit]
Description=Fluid Calendar Application
After=network.target postgresql.service

[Service]
Restart=always
WorkingDirectory=/opt/fluid-calendar
ExecStart=/usr/bin/npm run start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now fluid-calendar
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
