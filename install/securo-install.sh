#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/securo-finance/securo

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  nginx \
  redis-server \
  build-essential
systemctl enable -q --now redis-server
msg_ok "Installed Dependencies"

PG_VERSION="16" PG_MODULES="pgvector" setup_postgresql
PG_DB_NAME="securo" PG_DB_USER="securo" PG_DB_EXTENSIONS="vector" setup_postgresql_db
NODE_VERSION="22" setup_nodejs
UV_PYTHON="3.12" setup_uv

fetch_and_deploy_gh_release "securo" "securo-finance/securo" "tarball"

msg_info "Setting up Backend"
cd /opt/securo/backend
$STD uv venv --python 3.12 /opt/securo/backend/.venv
$STD uv pip install --python /opt/securo/backend/.venv -e .
msg_ok "Set up Backend"

msg_info "Configuring Securo"
mkdir -p /opt/securo_data
SECRET_KEY=$(openssl rand -hex 32)
cat <<EOF >/opt/securo_data/.env
DATABASE_URL=postgresql+asyncpg://securo:${PG_DB_PASS}@127.0.0.1:5432/securo
REDIS_URL=redis://127.0.0.1:6379/0
SECRET_KEY=${SECRET_KEY}
DEBUG=false
FRONTEND_URL=https://${LOCAL_IP}
EOF
ln -sf /opt/securo_data/.env /opt/securo/backend/.env
set -a
source /opt/securo_data/.env
set +a
$STD /opt/securo/backend/.venv/bin/alembic upgrade head
msg_ok "Configured Securo"

msg_info "Building Frontend (Patience)"
cd /opt/securo/frontend
export NODE_OPTIONS="--max-old-space-size=4096"
$STD npm install
$STD npm run build
msg_ok "Built Frontend"

msg_info "Generating Self-Signed Certificate"
create_self_signed_cert "securo"
msg_ok "Generated Self-Signed Certificate"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/securo.service
[Unit]
Description=Securo Backend (FastAPI)
After=network-online.target postgresql.service redis-server.service
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/securo/backend
EnvironmentFile=/opt/securo_data/.env
ExecStart=/opt/securo/backend/.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/securo-worker.service
[Unit]
Description=Securo Celery Worker
After=network-online.target postgresql.service redis-server.service
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/securo/backend
EnvironmentFile=/opt/securo_data/.env
ExecStart=/opt/securo/backend/.venv/bin/celery -A app.worker worker --loglevel=info --concurrency=2
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/securo-beat.service
[Unit]
Description=Securo Celery Beat
After=network-online.target postgresql.service redis-server.service
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/securo/backend
EnvironmentFile=/opt/securo_data/.env
ExecStart=/opt/securo/backend/.venv/bin/celery -A app.worker beat --loglevel=info
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now securo securo-worker securo-beat
msg_ok "Created Services"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/securo.conf
server {
    listen 80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl default_server;
    http2 on;
    server_name _;

    ssl_certificate /etc/ssl/securo/securo.crt;
    ssl_certificate_key /etc/ssl/securo/securo.key;

    client_max_body_size 25m;

    root /opt/securo/frontend/dist;
    index index.html;

    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF
nginx_enable_site securo.conf
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
