#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/tubearchivist/tubearchivist

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
  git \
  nginx \
  redis-server \
  atomicparsley \
  python3-dev \
  libldap2-dev \
  libsasl2-dev \
  libssl-dev \
  sqlite3 \
  ffmpeg
msg_ok "Installed Dependencies"

UV_PYTHON="3.13" setup_uv
NODE_VERSION="24" setup_nodejs

fetch_and_deploy_gh_release "deno" "denoland/deno" "prebuild" "latest" "/usr/local/bin" "deno-x86_64-unknown-linux-gnu.zip"

msg_info "Installing ElasticSearch"
setup_deb822_repo \
  "elastic-8.x" \
  "https://artifacts.elastic.co/GPG-KEY-elasticsearch" \
  "https://artifacts.elastic.co/packages/8.x/apt" \
  "stable" \
  "main"
ES_JAVA_OPTS="-Xms1g -Xmx1g" $STD apt install -y elasticsearch
msg_ok "Installed ElasticSearch"

msg_info "Configuring ElasticSearch"
cat <<EOF >/etc/elasticsearch/elasticsearch.yml
cluster.name: tubearchivist
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
path.repo: ["/var/lib/elasticsearch/snapshot"]
network.host: 127.0.0.1
xpack.security.enabled: false
xpack.security.transport.ssl.enabled: false
xpack.security.http.ssl.enabled: false
EOF
mkdir -p /var/lib/elasticsearch/snapshot
chown -R elasticsearch:elasticsearch /var/lib/elasticsearch/snapshot
cat <<EOF >/etc/elasticsearch/jvm.options.d/heap.options
-Xms1g
-Xmx1g
EOF
sysctl -w vm.max_map_count=262144 2>/dev/null || true
cat <<EOF >/etc/sysctl.d/99-elasticsearch.conf
vm.max_map_count=262144
EOF
systemctl enable -q --now elasticsearch
msg_ok "Configured ElasticSearch"

fetch_and_deploy_gh_release "tubearchivist" "tubearchivist/tubearchivist" "tarball"

msg_info "Building Frontend"
cd /opt/tubearchivist/frontend
$STD npm install
$STD npm run build:deploy
mkdir -p /opt/tubearchivist/backend/static
cp -r /opt/tubearchivist/frontend/dist/* /opt/tubearchivist/backend/static/
msg_ok "Built Frontend"

msg_info "Setting up Tube Archivist"
cp /opt/tubearchivist/docker_assets/backend_start.py /opt/tubearchivist/backend/
$STD uv venv /opt/tubearchivist/.venv
$STD uv pip install --python /opt/tubearchivist/.venv/bin/python -r /opt/tubearchivist/backend/requirements.txt
if [[ -f /opt/tubearchivist/backend/requirements.plugins.txt ]]; then
  mkdir -p /opt/yt_plugins/bgutil
  $STD uv pip install --python /opt/tubearchivist/.venv/bin/python --target /opt/yt_plugins/bgutil -r /opt/tubearchivist/backend/requirements.plugins.txt
fi
TA_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
ES_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
mkdir -p /opt/tubearchivist/{cache,media}
ln -sf /opt/tubearchivist/cache /cache
ln -sf /opt/tubearchivist/media /youtube
cat <<EOF >/opt/tubearchivist/.env
TA_HOST=http://${LOCAL_IP}:8000
TA_USERNAME=admin
TA_PASSWORD=${TA_PASSWORD}
TA_BACKEND_PORT=8080
TA_APP_DIR=/opt/tubearchivist/backend
TA_CACHE_DIR=/cache
TA_MEDIA_DIR=/youtube
ES_SNAPSHOT_DIR=/var/lib/elasticsearch/snapshot
ELASTIC_PASSWORD=${ES_PASSWORD}
REDIS_CON=redis://localhost:6379
ES_URL=http://localhost:9200
TZ=UTC
PYTHONUNBUFFERED=1
YTDLP_PLUGIN_DIRS=/opt/yt_plugins
EOF
{
  echo "Tube Archivist Credentials"
  echo "=========================="
  echo "Username: admin"
  echo "Password: ${TA_PASSWORD}"
  echo "Elasticsearch Password: ${ES_PASSWORD}"
} >~/tubearchivist.creds
systemctl enable -q --now redis-server
msg_ok "Set up Tube Archivist"

msg_info "Configuring Nginx"
sed -i 's/^user www-data;$/user root;/' /etc/nginx/nginx.conf
cat <<'EOF' >/etc/nginx/sites-available/default
server {
    listen 8000;

    location = /_auth {
        internal;
        proxy_pass http://localhost:8080/api/ping/;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header Host $http_host;
        proxy_set_header Cookie $http_cookie;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /cache/videos/ {
        auth_request /_auth;
        alias /cache/videos/;
    }

    location /cache/channels/ {
        auth_request /_auth;
        alias /cache/channels/;
    }

    location /cache/playlists/ {
        auth_request /_auth;
        alias /cache/playlists/;
    }

    location /media/ {
        auth_request /_auth;
        alias /youtube/;
        types {
            text/vtt vtt;
        }
    }

    location /youtube/ {
        auth_request /_auth;
        alias /youtube/;
        types {
            video/mp4 mp4;
        }
    }

    location /api {
        include proxy_params;
        proxy_pass http://localhost:8080;
    }

    location /admin {
        include proxy_params;
        proxy_pass http://localhost:8080;
    }

    location /static/ {
        alias /opt/tubearchivist/backend/staticfiles/;
    }

    root /opt/tubearchivist/backend/static;
    index index.html;

    location ~* ^/(?!static/|cache/).*\.(?:css|js|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
        try_files $uri $uri/ /index.html =404;
    }

    location = /index.html {
        add_header Cache-Control "no-store, no-cache, must-revalidate";
        add_header Pragma "no-cache";
        expires 0;
    }

    location / {
        add_header Cache-Control "no-store, no-cache, must-revalidate";
        add_header Pragma "no-cache";
        expires 0;
        try_files $uri $uri/ /index.html =404;
    }
}
EOF
systemctl enable -q nginx
systemctl restart nginx
msg_ok "Configured Nginx"

msg_info "Creating Services"
cat <<'RUNEOF' >/opt/tubearchivist/backend/run.sh
#!/bin/bash
set -e
cd /opt/tubearchivist/backend
set -a
source /opt/tubearchivist/.env
set +a
PYTHON=/opt/tubearchivist/.venv/bin/python

echo "Waiting for ElasticSearch..."
for i in $(seq 1 30); do
  if curl -sf http://localhost:9200/_cluster/health >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

$PYTHON manage.py migrate
$PYTHON manage.py collectstatic --noinput -c
$PYTHON manage.py ta_envcheck
$PYTHON manage.py ta_connection
$PYTHON manage.py ta_startup

exec $PYTHON backend_start.py
RUNEOF
chmod +x /opt/tubearchivist/backend/run.sh
ln -sf /opt/tubearchivist/.env /opt/tubearchivist/backend/.env
cat <<EOF >/etc/systemd/system/tubearchivist.service
[Unit]
Description=Tube Archivist Backend
After=network.target elasticsearch.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/tubearchivist/backend
EnvironmentFile=/opt/tubearchivist/.env
Environment=PATH=/opt/tubearchivist/.venv/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/opt/tubearchivist/backend/run.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/tubearchivist-celery.service
[Unit]
Description=Tube Archivist Celery Worker
After=tubearchivist.service redis-server.service elasticsearch.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/tubearchivist/backend
EnvironmentFile=/opt/tubearchivist/.env
Environment=PATH=/opt/tubearchivist/.venv/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/opt/tubearchivist/.venv/bin/celery -A task worker --loglevel=error --concurrency=4 --max-tasks-per-child=5 --max-memory-per-child=150000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/tubearchivist-beat.service
[Unit]
Description=Tube Archivist Celery Beat
After=tubearchivist.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/tubearchivist/backend
EnvironmentFile=/opt/tubearchivist/.env
Environment=PATH=/opt/tubearchivist/.venv/bin:/usr/local/bin:/usr/bin:/bin
ExecStartPre=/bin/bash -c 'for i in \$(seq 1 60); do sqlite3 /cache/db.sqlite3 "SELECT 1 FROM django_celery_beat_crontabschedule LIMIT 1" 2>/dev/null && exit 0; sleep 2; done; exit 1'
ExecStart=/opt/tubearchivist/.venv/bin/celery -A task beat --loglevel=error --scheduler django_celery_beat.schedulers:DatabaseScheduler
Restart=always
RestartSec=5
RuntimeMaxSec=3600

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tubearchivist tubearchivist-celery tubearchivist-beat
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
