#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/wger-project/wger

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
  redis-server \
  libpq-dev
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="sass" setup_nodejs
setup_uv
PG_VERSION="16" setup_postgresql
PG_DB_NAME="wger" PG_DB_USER="wger" setup_postgresql_db
fetch_and_deploy_gh_release "wger" "wger-project/wger" "tarball" "latest" "/opt/wger"

msg_info "Setting up wger"
mkdir -p /opt/wger/{static,media}
chmod o+w /opt/wger/media
cd /opt/wger
$STD corepack enable
$STD npm install
$STD npm run build:css:sass
$STD uv venv
$STD uv pip install . --group docker
SECRET_KEY=$(openssl rand -base64 40)
cat <<EOF >/opt/wger/.env
DJANGO_SETTINGS_MODULE=settings.main
PYTHONPATH=/opt/wger

DJANGO_DB_ENGINE=django.db.backends.postgresql
DJANGO_DB_DATABASE=${PG_DB_NAME}
DJANGO_DB_USER=${PG_DB_USER}
DJANGO_DB_PASSWORD=${PG_DB_PASS}
DJANGO_DB_HOST=localhost
DJANGO_DB_PORT=5432
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}

DJANGO_MEDIA_ROOT=/opt/wger/media
DJANGO_STATIC_ROOT=/opt/wger/static
DJANGO_STATIC_URL=/static/

ALLOWED_HOSTS=${LOCAL_IP},localhost,127.0.0.1
CSRF_TRUSTED_ORIGINS=http://${LOCAL_IP}:3000

USE_X_FORWARDED_HOST=True
SECURE_PROXY_SSL_HEADER=HTTP_X_FORWARDED_PROTO,http

DJANGO_CACHE_BACKEND=django_redis.cache.RedisCache
DJANGO_CACHE_LOCATION=redis://127.0.0.1:6379/1
DJANGO_CACHE_TIMEOUT=300
DJANGO_CACHE_CLIENT_CLASS=django_redis.client.DefaultClient
AXES_CACHE_ALIAS=default

USE_CELERY=True
CELERY_BROKER=redis://127.0.0.1:6379/2
CELERY_BACKEND=redis://127.0.0.1:6379/2

SITE_URL=http://${LOCAL_IP}:3000
SECRET_KEY=${SECRET_KEY}
EOF
set -a && source /opt/wger/.env && set +a
$STD uv run wger bootstrap
$STD uv run python manage.py collectstatic --no-input
cat <<EOF | uv run python manage.py shell
from django.contrib.auth import get_user_model
User = get_user_model()

user, created = User.objects.get_or_create(
    username="admin",
    defaults={"email": "admin@localhost"},
)

if created:
    user.set_password("${PG_DB_PASS}")
    user.is_superuser = True
    user.is_staff = True
    user.save()
EOF
msg_ok "Set up wger"
msg_info "Creating Config and Services"
cat <<EOF >/etc/systemd/system/wger.service
[Unit]
Description=wger Gunicorn
After=network.target

[Service]
User=root
WorkingDirectory=/opt/wger
EnvironmentFile=/opt/wger/.env
ExecStart=/opt/wger/.venv/bin/gunicorn \
  --bind 127.0.0.1:8000 \
  --workers 3 \
  --threads 2 \
  --timeout 120 \
  wger.wsgi:application
Restart=always

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/celery.service
[Unit]
Description=wger Celery Worker
After=network.target redis-server.service
Requires=redis-server.service

[Service]
WorkingDirectory=/opt/wger
EnvironmentFile=/opt/wger/.env
ExecStart=/opt/wger/.venv/bin/celery -A wger worker -l info
Restart=always

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /var/lib/wger/celery
chmod 700 /var/lib/wger/celery
cat <<EOF >/etc/systemd/system/celery-beat.service
[Unit]
Description=wger Celery Beat
After=network.target redis-server.service
Requires=redis-server.service

[Service]
WorkingDirectory=/opt/wger
EnvironmentFile=/opt/wger/.env
ExecStart=/opt/wger/.venv/bin/celery -A wger beat -l info \
  --schedule /var/lib/wger/celery/celerybeat-schedule
Restart=always

[Install]
WantedBy=multi-user.target
EOF
cat <<'EOF' >/etc/nginx/sites-available/wger
server {
    listen 3000;
    server_name _;

    client_max_body_size 20M;

    location /static/ {
        alias /opt/wger/static/;
        expires 30d;
    }

    location /media/ {
        alias /opt/wger/media/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
}
EOF
$STD rm -f /etc/nginx/sites-enabled/default
$STD ln -sf /etc/nginx/sites-available/wger /etc/nginx/sites-enabled/wger
systemctl enable -q --now redis-server nginx wger celery celery-beat
systemctl restart nginx
msg_ok "Created Config and Services"

motd_ssh
customize
cleanup_lxc
