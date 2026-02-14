#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/PatcMmon/PatchMon

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  nginx \
  redis-server
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_NAME="patchmon_db" PG_DB_USER="patchmon_usr" setup_postgresql_db

fetch_and_deploy_gh_release "PatchMon" "PatchMon/PatchMon" "tarball" "latest" "/opt/patchmon"

msg_info "Configuring PatchMon"
VERSION=$(get_latest_github_release "PatchMon/PatchMon")
export NODE_ENV=production
cd /opt/patchmon
$STD npm install --no-audit --no-fund --no-save --ignore-scripts

cd /opt/patchmon/frontend
cat <<EOF >./.env
VITE_API_URL=http://${LOCAL_IP}:3001/api/v1
VITE_APP_NAME=PatchMon
VITE_APP_VERSION=${VERSION}
EOF
$STD npm install --no-audit --no-fund --no-save --ignore-scripts --include=dev
$STD npm run build

JWT_SECRET="$(openssl rand -hex 64)"
mv /opt/patchmon/backend/env.example /opt/patchmon/backend/.env
sed -i -e "s|DATABASE_URL=.*|DATABASE_URL=\"postgresql://$PG_DB_USER:$PG_DB_PASS@localhost:5432/$PG_DB_NAME\"|" \
  -e "/JWT_SECRET/s/[=$].*/=$JWT_SECRET/" \
  -e "\|CORS_ORIGIN|s|localhost|$LOCAL_IP|" \
  -e "/PORT=3001/aSERVER_PROTOCOL=http \\
    SERVER_HOST=$LOCAL_IP \\
    SERVER_PORT=3000" \
  -e '/_ENV=production/aTRUST_PROXY=1' \
  -e '/REDIS_USER=.*/,+1d' /opt/patchmon/backend/.env

cd /opt/patchmon/backend
$STD npm run db:generate
$STD npx prisma migrate deploy
msg_ok "Configured PatchMon"

msg_info "Configuring Nginx"
cp /opt/patchmon/docker/nginx.conf.template /etc/nginx/sites-available/patchmon.conf
sed -i -e 's|proxy_pass .*|proxy_pass http://127.0.0.1:3001;|' \
  -e '\|try_files |i\        root /opt/patchmon/frontend/dist;' \
  -e 's|alias.*|alias /opt/patchmon/frontend/dist/assets;|' \
  -e '\|expires 1y|i\        root /opt/patchmon/frontend/dist;' /etc/nginx/sites-available/patchmon.conf
ln -sf /etc/nginx/sites-available/patchmon.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
$STD nginx -t
systemctl restart nginx
msg_ok "Configured Nginx"

msg_info "Creating service"
cat <<EOF >/etc/systemd/system/patchmon-server.service
[Unit]
Description=PatchMon Service
After=network.target postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/patchmon/backend
ExecStart=/usr/bin/npm run start
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PATH=/usr/bin:/usr/local/bin
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/patchmon

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now patchmon-server
msg_ok "Created and started service"

motd_ssh
customize
cleanup_lxc
