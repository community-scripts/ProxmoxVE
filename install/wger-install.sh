#!/usr/bin/env bash
# Copyright (c) 2021-2025 community-scripts ORG
# Original Author: Slaviša Arežina (tremor021)
# Revamped Script: Floris Claessens (FlorisCl)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
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
    rsync
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.13" setup_uv
NODE_VERSION="22" NODE_MODULE="npm,sass" setup_nodejs
corepack enable

fetch_and_deploy_gh_release "wger" "wger-project/wger" "tarball" "latest"

WG_IP="$(hostname -I | awk '{print $1}')"
WG_PORT="3000"
WG_URL="http://${WG_IP}:${WG_PORT}"

msg_info "Creating env variables"
cat <<EOF >/opt/wger/wger.env
DJANGO_SETTINGS_MODULE=settings.main
PYTHONPATH=/opt/wger

# Networking / security
ALLOWED_HOSTS=${WG_IP},localhost,127.0.0.1
CSRF_TRUSTED_ORIGINS=${WG_URL}

USE_X_FORWARDED_HOST=True
SECURE_PROXY_SSL_HEADER=HTTP_X_FORWARDED_PROTO,http

SESSION_COOKIE_SECURE=False
CSRF_COOKIE_SECURE=False

# Paths
DJANGO_DB_DATABASE=/opt/wger/db/database.sqlite
DJANGO_MEDIA_ROOT=/opt/wger/media
DJANGO_STATIC_ROOT=/opt/wger/static
DJANGO_STATIC_URL=/static/

# Cache (Mandatory for wger)
DJANGO_CACHE_BACKEND=django_redis.cache.RedisCache
DJANGO_CACHE_LOCATION=redis://127.0.0.1:6379/1
DJANGO_CACHE_TIMEOUT=300
DJANGO_CACHE_CLIENT_CLASS=django_redis.client.DefaultClient
AXES_CACHE_ALIAS=default

# URL
SITE_URL=${WG_URL}

# Celery
USE_CELERY=True
CELERY_BROKER=redis://localhost:6379/2
CELERY_BACKEND=redis://localhost:6379/2
EOF
msg_ok "Env variables created"

msg_info "Setting up wger"
  mkdir -p /opt/wger/{static,media}

  chmod -R 755 /opt/wger

  mkdir -p /opt/wger/db

  cd /opt/wger
  $STD uv venv
  $STD uv sync --group docker
  $STD uv pip install psycopg2-binary

  set -a
  source /opt/wger/wger.env
  set +a

  $STD uv run wger bootstrap
  $STD uv run python manage.py collectstatic --no-input


msg_ok "Finished setting up wger"

msg_info "Creating wger service"
  cat <<EOF >/etc/systemd/system/wger.service
[Unit]
Description=wger (Gunicorn + Django)
After=network.target redis-server.service
Requires=redis-server.service

[Service]
User=root
Group=root
WorkingDirectory=/opt/wger
EnvironmentFile=/opt/wger/wger.env
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
msg_ok "Created wger service"

msg_info "Adding nginx"
  cat <<'EOF' >/etc/nginx/sites-available/wger
server {
    listen 3000;
    server_name _;

    client_max_body_size 20M;

    location /static/ {
        alias /opt/wger/static/;
        access_log off;
        expires 30d;
    }

    location /media/ {
        alias /opt/wger/media/;
        access_log off;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;

        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_redirect off;
    }
}
EOF

  ln -sf /etc/nginx/sites-available/wger /etc/nginx/sites-enabled/wger
  rm -f /etc/nginx/sites-enabled/default
msg_ok "Nginx added"

msg_info "Creating Celery worker service"
  cat <<EOF >/etc/systemd/system/celery.service
[Unit]
Description=wger Celery Worker
After=network.target redis-server.service
Requires=redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/wger
EnvironmentFile=/opt/wger/wger.env
ExecStart=/opt/wger/.venv/bin/celery -A wger worker -l info
Restart=always
PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=/opt/wger

[Install]
WantedBy=multi-user.target
EOF
msg_ok "Celery service created"

msg_info "Creating Celery beat service"
  mkdir -p /var/lib/wger/celery
  chmod 755 /var/lib/wger
  chmod 700 /var/lib/wger/celery
  msg_ok "Celery Beat schedule directory ready"

  cat <<EOF >/etc/systemd/system/celery-beat.service
  [Unit]
  Description=wger Celery Beat
  After=network.target redis-server.service
  Requires=redis-server.service

  [Service]
  Type=simple
  User=root
  WorkingDirectory=/opt/wger
  EnvironmentFile=/opt/wger/wger.env
  ExecStart=/opt/wger/.venv/bin/celery -A wger beat -l info --schedule /var/lib/wger/celery/celerybeat-schedule
  Restart=always
  PrivateTmp=true
  NoNewPrivileges=true
  ProtectSystem=strict
  ReadWritePaths=/opt/wger /var/lib/wger

  [Install]
  WantedBy=multi-user.target
EOF
msg_ok "Created Celery beat service"

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now redis-server nginx wger celery celery-beat 
systemctl restart wger
systemctl restart celery
systemctl restart nginx

motd_ssh
customize
cleanup_lxc

