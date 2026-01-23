#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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
$STD apt install -y zip
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="fluiddb" PG_DB_USER="fluiduser" setup_postgresql_db
NODE_VERSION="20" setup_nodejs
fetch_and_deploy_gh_release "fluid-calendar" "dotnetfactory/fluid-calendar" "tarball"

msg_info "Configuring fluid-calendar"
NEXTAUTH_SECRET="$(openssl rand -base64 44 | tr -dc 'a-zA-Z0-9' | cut -c1-32)"
echo "NextAuth Secret: $NEXTAUTH_SECRET" >>~/$APPLICATION.creds
cat <<EOF >/opt/fluid-calendar/.env
DATABASE_URL="postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}"

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
msg_ok "Configured fluid-calendar"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/fluid-calendar.service
[Unit]
Description=Fluid Calendar Application
After=network.target postgresql.service

[Service]
Restart=always
WorkingDirectory=/opt/fluid-calendar
EnvironmentFile=/opt/fluid-calendar/.env
ExecStart=/usr/bin/npm run start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now fluid-calendar
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
