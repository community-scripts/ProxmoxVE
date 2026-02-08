#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: TuroYT
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TuroYT/snowshare

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_USER="snowshare" PG_DB_NAME="snowshare" setup_postgresql_db
fetch_and_deploy_gh_release "snowshare" "TuroYT/snowshare" "tarball"

msg_info "Installing SnowShare"
cd /opt/snowshare
$STD npm ci
cat <<EOF >/opt/snowshare.env
DATABASE_URL="postgresql://$PG_DB_USER:$PG_DB_PASS@localhost:5432/$PG_DB_NAME"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="$(openssl rand -base64 32)"
ALLOW_SIGNUP=true
NODE_ENV=production
EOF
set -a
source /opt/snowshare.env
set +a
$STD npx prisma generate
$STD npx prisma migrate deploy
$STD npm run build
cat <<EOF >/etc/systemd/system/snowshare.service
[Unit]
Description=SnowShare - Modern File Sharing Platform
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/snowshare
EnvironmentFile=/opt/snowshare/.env
ExecStart=/usr/bin/npm start
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now snowshare
msg_ok "Installed SnowShare"

msg_info "Setting up Cleanup Cron Job"
cat <<EOF >/etc/cron.d/snowshare-cleanup
0 2 * * * root cd /opt/snowshare && /usr/bin/npm run cleanup:expired >> /var/log/snowshare-cleanup.log 2>&1
EOF
msg_ok "Set up Cleanup Cron Job"

motd_ssh
customize
cleanup_lxc
