#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dannyvfilms/Floppy

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
  redis-server
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "floppy" "dannyvfilms/Floppy" "tarball"
PYTHON_VERSION="3.12" UV_PROJECT_DIR="/opt/floppy" setup_uv

msg_info "Installing Python Dependencies"
cd /opt/floppy
$STD uv sync --locked --no-default-groups
msg_ok "Installed Python Dependencies"

var_admin_user="${var_admin_user:-admin}"
var_admin_pass="${var_admin_pass:-$(random_password 16)}"

msg_info "Configuring Floppy"
mkdir -p /opt/floppy_data/{db,backups,logs}
cat <<EOF >/opt/floppy_data/.env
SECRET=$(random_password 50)
DEBUG=False
ADMIN_ENABLED=False
DEMO_ACCOUNT_ENABLED=False
REGISTRATION=False
ALLOWED_HOSTS=*
TZ=$(cat /etc/timezone)
FLOPPY_DATA_DIR=/opt/floppy_data/db
BACKUP_DIR=/opt/floppy_data/backups
LOG_DIR=/opt/floppy_data/logs
REDIS_URL=redis://127.0.0.1:6379
VERSION=v$(cat ~/.floppy)
DJANGO_SUPERUSER_USERNAME=${var_admin_user}
DJANGO_SUPERUSER_PASSWORD=${var_admin_pass}
EOF
chmod 600 /opt/floppy_data/.env
msg_ok "Configured Floppy"

msg_info "Setting up Floppy Database (Patience)"
set -a
source /opt/floppy_data/.env
set +a
cd /opt/floppy/src
$STD /opt/floppy/.venv/bin/python manage.py migrate --noinput
$STD /opt/floppy/.venv/bin/python manage.py collectstatic --noinput
$STD /opt/floppy/.venv/bin/python manage.py createsuperuser --noinput --email "${var_admin_user}@localhost"
msg_ok "Set up Floppy Database"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/floppy
server {
    listen 8000;
    server_name _;
    client_max_body_size 512M;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$http_x_forwarded_proto;
    }

    location /static/ {
        alias /opt/floppy/src/staticfiles/;
        expires 30d;
        add_header Cache-Control "public";
    }
}
EOF
nginx_enable_site "floppy"
msg_ok "Configured Nginx"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/floppy.service
[Unit]
Description=Floppy Web
After=network.target redis-server.service
Requires=redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/floppy/src
EnvironmentFile=/opt/floppy_data/.env
ExecStart=/opt/floppy/.venv/bin/gunicorn --config python:config.gunicorn config.wsgi:application
KillMode=mixed
TimeoutStopSec=30
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/floppy-celery.service
[Unit]
Description=Floppy Celery Worker
After=network.target redis-server.service floppy.service
Requires=redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/floppy/src
EnvironmentFile=/opt/floppy_data/.env
Environment=FLOPPY_PROCESS_ROLE=combined
ExecStart=/opt/floppy/.venv/bin/celery --app config worker --beat --scheduler django --queues celery,interactive,discover --loglevel INFO --without-mingle --without-gossip
KillMode=mixed
TimeoutStopSec=60
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now redis-server floppy floppy-celery
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
