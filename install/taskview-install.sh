#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Gimanh/taskview-community

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

NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs
PG_VERSION="18" setup_postgresql
PG_DB_NAME="taskview" PG_DB_USER="taskview" setup_postgresql_db

msg_info "Configuring PostgreSQL for TaskView"
# Every migration run terminates all other sessions on the database, autovacuum workers included
$STD sudo -u postgres psql -c "GRANT pg_signal_autovacuum_worker TO taskview;"
msg_ok "Configured PostgreSQL for TaskView"

fetch_and_deploy_gh_release "taskview" "Gimanh/taskview-community" "tarball"

msg_info "Building TaskView"
cd /opt/taskview
$STD pnpm install --frozen-lockfile
cd /opt/taskview/api
$STD pnpm run build:docker
$STD pnpm run build:migration
cp -r src/migrations/taskview dist-migration/
cd /opt/taskview/web
# upstream's build script type-checks before Vite has generated the auto-import types, which fails on a fresh checkout
$STD pnpm run build:packages
$STD pnpm run build-only
msg_ok "Built TaskView"

msg_info "Configuring TaskView"
mkdir -p /opt/taskview_data
cat <<EOF >/opt/taskview_data/.env
NODE_ENV=production
DB_HOST=localhost
DB_PORT=5432
DB_NAME=taskview
DB_USER=taskview
DB_PASSWORD=${PG_DB_PASS}
APP_PORT=1401
APP_URL=http://${LOCAL_IP}
CORS_ALLOWED_ORIGINS=http://${LOCAL_IP}
TRUST_PROXY=1
JWT_ALG=HS256
JWT_SIGN=$(openssl rand -hex 64)
ACCESS_LIFE_TIME=3d
REFRESH_LIFE_TIME=9d
ENCRYPTION_KEY=$(openssl rand -hex 32)
PASSWORD_CHANGE_CONFIRMATION=password
EOF
chmod 600 /opt/taskview_data/.env
msg_ok "Configured TaskView"

msg_info "Creating TaskView Database Schema"
# The migration reads DB_* from the .env in its working directory
cd /opt/taskview_data
$STD node /opt/taskview/api/dist-migration/taskview-db-migration.js --create
msg_ok "Created TaskView Database Schema"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/taskview
server {
    listen 80;
    server_name _;
    root /opt/taskview/web/dist;
    index index.html;

    gzip_types text/css application/javascript application/json image/svg+xml;

    location ~ ^/(module|scim|\.well-known)/ {
        proxy_pass http://127.0.0.1:1401;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Pins the web client to the API behind this same origin and hides the server selector
    location = /config.js {
        default_type application/javascript;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        return 200 'window.__TASKVIEW_CONFIG__ = { apiUrl: window.location.origin };';
    }

    location = /index.html {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF
nginx_enable_site "taskview"
msg_ok "Configured Nginx"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/taskview.service
[Unit]
Description=TaskView API
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/taskview_data
EnvironmentFile=/opt/taskview_data/.env
ExecStart=/usr/bin/node /opt/taskview/api/dist/taskview-server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now taskview
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
