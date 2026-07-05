#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ZimengXiong/ExcaliDash

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
  make \
  nginx
msg_ok "Installed Dependencies"

NODE_VERSION="20" setup_nodejs
PG_VERSION="18" setup_postgresql
PG_DB_NAME="excalidash" PG_DB_USER="excalidash" setup_postgresql_db

fetch_and_deploy_gh_release "excalidash" "ZimengXiong/ExcaliDash" "tarball"

msg_info "Configuring Database Provider"
cd /opt/excalidash/backend
sed -i '/datasource db {/,/}/ s/provider = env("[^"]*")/provider = "postgresql"/' prisma/schema.prisma
sed -i '/datasource db {/,/}/ s/provider = "[^"]*"/provider = "postgresql"/' prisma/schema.prisma
mv prisma/migrations/postgresql/* prisma/migrations/
rm -rf prisma/migrations/sqlite prisma/migrations/postgresql
msg_ok "Configured Database Provider"

msg_info "Building Backend"
cd /opt/excalidash/backend
$STD npm ci
$STD npx prisma generate
$STD npx tsc
msg_ok "Built Backend"

msg_info "Building Frontend"
cd /opt/excalidash/frontend
$STD npm ci
$STD npm run build
msg_ok "Built Frontend"

msg_info "Configuring Application"
mkdir -p /opt/excalidash_data
mkdir -p /var/www/excalidash
cp -r /opt/excalidash/frontend/dist/. /var/www/excalidash/
cat <<EOF >/opt/excalidash_data/.env
DATABASE_PROVIDER=postgresql
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}
PORT=8000
NODE_ENV=production
FRONTEND_URL=http://${LOCAL_IP}:6767
AUTH_MODE=local
TRUST_PROXY=false
RUN_MIGRATIONS=false
JWT_SECRET=$(openssl rand -hex 32)
CSRF_SECRET=$(openssl rand -base64 32)
EOF
ln -sf /opt/excalidash_data/.env /opt/excalidash/backend/.env
cd /opt/excalidash/backend
set -a && source /opt/excalidash_data/.env && set +a
$STD npx prisma migrate deploy
msg_ok "Configured Application"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/excalidash
server {
    listen 6767;
    server_name _;
    root /var/www/excalidash;
    index index.html;
    client_max_body_size 50M;

    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }

    location /socket.io/ {
        proxy_pass http://127.0.0.1:8000/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF
ln -sf /etc/nginx/sites-available/excalidash /etc/nginx/sites-enabled/excalidash
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx
msg_ok "Configured Nginx"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/excalidash.service
[Unit]
Description=ExcaliDash Service
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/excalidash/backend
EnvironmentFile=/opt/excalidash/backend/.env
ExecStart=/usr/bin/node dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now excalidash
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
