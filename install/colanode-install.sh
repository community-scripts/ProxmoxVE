#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://colanode.com/

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
  redis-server \
  nginx
msg_ok "Installed Dependencies"

PG_VERSION="17" PG_MODULES="pgvector" setup_postgresql
PG_DB_NAME="colanode_db" PG_DB_USER="colanode" PG_DB_EXTENSIONS="vector" setup_postgresql_db
NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "colanode" "colanode/colanode" "tarball"

msg_info "Building Application"
cd /opt/colanode
export NODE_OPTIONS="--max-old-space-size=4096"
$STD npm install
$STD npm run build -w @colanode/core
$STD npm run build -w @colanode/crdt
$STD npm run build -w @colanode/server
$STD npm run build -w @colanode/client
$STD npm run build -w @colanode/ui
$STD npm run build -w @colanode/web
$STD npm prune --production
unset NODE_OPTIONS
msg_ok "Built Application"

msg_info "Configuring Application"
mkdir -p /var/lib/colanode/storage /var/www/colanode
cp -r /opt/colanode/apps/web/dist/. /var/www/colanode/
cat <<EOF >/opt/colanode/.env
POSTGRES_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}
REDIS_URL=redis://127.0.0.1:6379
NODE_ENV=production
EOF
msg_ok "Configured Application"

msg_info "Configuring Nginx"
create_self_signed_cert "colanode"
# Make cert available for browser import (required for Service Worker to work)
cp /etc/ssl/colanode/colanode.crt /var/www/colanode/colanode.crt
cat <<EOF >/etc/nginx/sites-available/colanode
server {
    listen 4000 ssl;
    server_name _;
    root /var/www/colanode;
    index index.html;

    ssl_certificate /etc/ssl/colanode/colanode.crt;
    ssl_certificate_key /etc/ssl/colanode/colanode.key;

    # Required for SharedArrayBuffer / OPFS SQLite (WASM)
    add_header Cross-Origin-Opener-Policy "same-origin" always;
    add_header Cross-Origin-Embedder-Policy "require-corp" always;

    # Proxy API and WebSocket traffic to the Node.js server
    location ~ ^/(config|client)(/.*)?$ {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Serve self-signed cert for browser import
    location = /colanode.crt {
        default_type application/x-x509-ca-cert;
    }

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF
ln -sf /etc/nginx/sites-available/colanode /etc/nginx/sites-enabled/colanode
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx
msg_ok "Configured Nginx"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/colanode-server.service
[Unit]
Description=Colanode Server
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/colanode
EnvironmentFile=/opt/colanode/.env
ExecStart=/usr/bin/node apps/server/dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now colanode-server
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
