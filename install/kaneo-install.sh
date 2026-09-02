#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: onionrings29
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/usekaneo/kaneo

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="kaneo" PG_DB_USER="kaneo" setup_postgresql_db
fetch_and_deploy_gh_release "kaneo" "usekaneo/kaneo" "tarball"

PNPM_VERSION=$(sed -n 's/.*"packageManager": "pnpm@\([^"+]*\).*/\1/p' /opt/kaneo/package.json)
NODE_VERSION="22" NODE_MODULE="pnpm@${PNPM_VERSION:-10.32.1}" setup_nodejs

msg_info "Configuring Kaneo"
cat <<EOF >/opt/kaneo/.env
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}
AUTH_SECRET=$(openssl rand -hex 32)
KANEO_CLIENT_URL=http://${LOCAL_IP}:5173
KANEO_API_URL=http://${LOCAL_IP}:5173/api
EOF
cat <<EOF >/opt/kaneo/apps/web/.env.production
VITE_API_URL=http://${LOCAL_IP}:5173/api
VITE_CLIENT_URL=http://${LOCAL_IP}:5173
EOF
msg_ok "Configured Kaneo"

msg_info "Building Kaneo"
cd /opt/kaneo
export NODE_OPTIONS="--max-old-space-size=4096"
HUSKY=0 $STD pnpm install --frozen-lockfile
$STD pnpm exec turbo build --filter=@kaneo/api --filter=@kaneo/web
unset NODE_OPTIONS
msg_ok "Built Kaneo"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/kaneo.service
[Unit]
Description=Kaneo API
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/kaneo
Environment=NODE_ENV=production
EnvironmentFile=/opt/kaneo/.env
ExecStart=/usr/bin/node /opt/kaneo/apps/api/dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now kaneo
msg_ok "Created Service"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/kaneo
server {
  listen 5173;
  server_name _;

  add_header X-Content-Type-Options "nosniff" always;
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header Referrer-Policy "strict-origin-when-cross-origin" always;
  client_max_body_size 25M;

  gzip on;
  gzip_vary on;
  gzip_min_length 1000;
  gzip_proxied any;
  gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
  gzip_comp_level 6;

  location = /.well-known/oauth-protected-resource/api/mcp {
    proxy_pass http://127.0.0.1:1337/.well-known/oauth-protected-resource/api/mcp;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location = /.well-known/oauth-authorization-server/api {
    proxy_pass http://127.0.0.1:1337/.well-known/oauth-authorization-server/api;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location /.well-known/ {
    return 404;
  }

  location /api/ {
    proxy_pass http://127.0.0.1:1337/api/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location / {
    root /opt/kaneo/apps/web/dist;
    index index.html;
    try_files \$uri \$uri/ /index.html;
  }
}
EOF
nginx_enable_site kaneo
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
