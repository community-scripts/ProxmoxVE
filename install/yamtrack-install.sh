#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/FuzzyGrim/Yamtrack

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

PG_VERSION="16" setup_postgresql
PG_DB_NAME="yamtrack" PG_DB_USER="yamtrack" setup_postgresql_db
PYTHON_VERSION="3.12" setup_uv

fetch_and_deploy_gh_release "yamtrack" "FuzzyGrim/Yamtrack" "tarball"

msg_info "Installing Python Dependencies"
cd /opt/yamtrack
$STD uv venv .venv
$STD uv pip install --no-cache-dir -r requirements.txt
msg_ok "Installed Python Dependencies"

msg_info "Configuring Yamtrack"
SECRET=$(openssl rand -hex 32)
cat <<EOF >/opt/yamtrack/src/.env
SECRET=${SECRET}
DB_HOST=localhost
DB_NAME=${PG_DB_NAME}
DB_USER=${PG_DB_USER}
DB_PASSWORD=${PG_DB_PASS}
DB_PORT=5432
REDIS_URL=redis://localhost:6379
URLS=http://${LOCAL_IP}:8000
EOF

cd /opt/yamtrack/src
$STD /opt/yamtrack/.venv/bin/python manage.py migrate
$STD /opt/yamtrack/.venv/bin/python manage.py collectstatic --noinput
msg_ok "Configured Yamtrack"

msg_info "Configuring Nginx"
rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
cp /opt/yamtrack/nginx.conf /etc/nginx/nginx.conf
sed -i 's|user abc;|user www-data;|' /etc/nginx/nginx.conf
sed -i 's|pid /tmp/nginx.pid;|pid /run/nginx.pid;|' /etc/nginx/nginx.conf
sed -i 's|/yamtrack/staticfiles/|/opt/yamtrack/src/staticfiles/|' /etc/nginx/nginx.conf
sed -i 's|error_log /dev/stderr|error_log /var/log/nginx/error.log|' /etc/nginx/nginx.conf
sed -i 's|access_log /dev/stdout|access_log /var/log/nginx/access.log|' /etc/nginx/nginx.conf
$STD nginx -t
systemctl enable -q nginx
$STD systemctl restart nginx
msg_ok "Configured Nginx"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/yamtrack.service
[Unit]
Description=Yamtrack Gunicorn
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/yamtrack/src
ExecStart=/opt/yamtrack/.venv/bin/gunicorn config.wsgi:application -b 127.0.0.1:8001 -w 2 --timeout 120
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/yamtrack-celery.service
[Unit]
Description=Yamtrack Celery Worker
After=network.target postgresql.service redis-server.service yamtrack.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/yamtrack/src
ExecStart=/opt/yamtrack/.venv/bin/celery -A config worker --beat --scheduler django --loglevel INFO
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now redis-server yamtrack yamtrack-celery
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
