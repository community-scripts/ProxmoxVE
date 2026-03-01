#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ) | DevelopmentCats | AlphaLawless
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://romm.app | Github: https://github.com/rommapp/romm

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  acl \
  git \
  build-essential \
  libssl-dev \
  libffi-dev \
  libmagic-dev \
  python3-dev \
  python3-pip \
  python3-venv \
  libmariadb3 \
  libmariadb-dev \
  libpq-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  zlib1g-dev \
  liblzma-dev \
  libncurses5-dev \
  libncursesw5-dev \
  redis-server \
  redis-tools \
  p7zip-full \
  tzdata \
  nginx
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.13" setup_uv
NODE_VERSION="24" setup_nodejs
setup_mariadb
MARIADB_DB_NAME="romm" MARIADB_DB_USER="romm" setup_mariadb_db

msg_info "Creating directories"
mkdir -p /opt/romm \
  /var/lib/romm/config \
  /var/lib/romm/resources \
  /var/lib/romm/assets/{saves,states,screenshots} \
  /var/lib/romm/library/roms \
  /var/lib/romm/library/bios
msg_ok "Created directories"

msg_info "Creating configuration file"
cat <<'EOF' >/var/lib/romm/config/config.yml
# RomM Configuration File
# Documentation: https://docs.romm.app/latest/Getting-Started/Configuration-File/
# Only uncomment the lines you want to use/modify

# exclude:
#   platforms:
#     - excluded_folder_a
#   roms:
#     single_file:
#       extensions:
#         - xml
#         - txt
#       names:
#         - '._*'
#         - '*.nfo'
#     multi_file:
#       names:
#         - downloaded_media
#         - media

# system:
#   platforms:
#     gc: ngc
#     ps1: psx

# The folder name where your roms are located (relative to library path)
# filesystem:
#   roms_folder: 'roms'

# scan:
#   priority:
#     metadata:
#       - "igdb"
#       - "moby"
#       - "ss"
#       - "ra"
#     artwork:
#       - "igdb"
#       - "moby"
#       - "ss"
#     region:
#       - "us"
#       - "eu"
#       - "jp"
#     language:
#       - "en"
#   media:
#     - box2d
#     - box3d
#     - screenshot
#     - manual

# emulatorjs:
#   debug: false
#   cache_limit: null
EOF
chmod 644 /var/lib/romm/config/config.yml
msg_ok "Created configuration file"

fetch_and_deploy_gh_release "RAHasher" "RetroAchievements/RALibretro" "prebuild" "latest" "/opt/RALibretro" "RAHasher-x64-Linux-*.zip"
cp /opt/RALibretro/RAHasher /usr/bin/RAHasher
chmod +x /usr/bin/RAHasher

fetch_and_deploy_gh_release "romm" "rommapp/romm"

msg_info "Creating environment file"
sed -i 's/^supervised no/supervised systemd/' /etc/redis/redis.conf
systemctl restart redis-server
systemctl enable -q --now redis-server
AUTH_SECRET_KEY=$(openssl rand -hex 32)

cat <<EOF >/opt/romm/.env
ROMM_BASE_PATH=/var/lib/romm
ROMM_CONFIG_PATH=/var/lib/romm/config/config.yml
WEB_CONCURRENCY=4

DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=$MARIADB_DB_NAME
DB_USER=$MARIADB_DB_USER
DB_PASSWD=$MARIADB_DB_PASS

REDIS_HOST=127.0.0.1
REDIS_PORT=6379

ROMM_AUTH_SECRET_KEY=$AUTH_SECRET_KEY
DISABLE_DOWNLOAD_ENDPOINT_AUTH=false
DISABLE_CSRF_PROTECTION=false

ENABLE_RESCAN_ON_FILESYSTEM_CHANGE=true
RESCAN_ON_FILESYSTEM_CHANGE_DELAY=5

ENABLE_SCHEDULED_RESCAN=true
SCHEDULED_RESCAN_CRON=0 3 * * *
ENABLE_SCHEDULED_UPDATE_SWITCH_TITLEDB=true
SCHEDULED_UPDATE_SWITCH_TITLEDB_CRON=0 4 * * *

LOGLEVEL=INFO
EOF

chmod 600 /opt/romm/.env
msg_ok "Created environment file"

msg_info "Setting up RomM Backend"
cd /opt/romm
export UV_CONCURRENT_DOWNLOADS=1
$STD uv sync --all-extras
cd /opt/romm/backend
$STD uv run alembic upgrade head
msg_ok "Set up RomM Backend"

msg_info "Setting up RomM Frontend"
cd /opt/romm/frontend
$STD npm install
$STD npm run build

cp -rf /opt/romm/frontend/assets/* /opt/romm/frontend/dist/assets/

mkdir -p /opt/romm/frontend/dist/assets/romm
ln -sfn /var/lib/romm/resources /opt/romm/frontend/dist/assets/romm/resources
ln -sfn /var/lib/romm/assets /opt/romm/frontend/dist/assets/romm/assets
msg_ok "Set up RomM Frontend"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/romm
upstream romm_backend {
    server 127.0.0.1:5000;
}

map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 80;
    server_name _;
    root /opt/romm/frontend/dist;
    client_max_body_size 0;

    # Frontend SPA
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Static assets
    location /assets {
        alias /opt/romm/frontend/dist/assets;
        try_files $uri $uri/ =404;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # EmulatorJS player - requires COOP/COEP headers for SharedArrayBuffer
    location ~ ^/rom/.*/ejs$ {
        add_header Cross-Origin-Embedder-Policy "require-corp";
        add_header Cross-Origin-Opener-Policy "same-origin";
        try_files $uri /index.html;
    }

    # Backend API
    location /api {
        proxy_pass http://romm_backend;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket and Netplay
    location ~ ^/(ws|netplay) {
        proxy_pass http://romm_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }

    # OpenAPI docs
    location = /openapi.json {
        proxy_pass http://romm_backend;
    }

    # Internal library file serving
    location /library/ {
        internal;
        alias /var/lib/romm/library/;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/romm /etc/nginx/sites-enabled/romm
systemctl restart nginx
systemctl enable -q --now nginx
msg_ok "Configured Nginx"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/romm-backend.service
[Unit]
Description=RomM Backend
After=network.target mariadb.service redis-server.service
Requires=mariadb.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/romm/backend
EnvironmentFile=/opt/romm/.env
Environment="PYTHONPATH=/opt/romm"
ExecStart=/opt/romm/.venv/bin/python main.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/romm-worker.service
[Unit]
Description=RomM RQ Worker
After=network.target mariadb.service redis-server.service romm-backend.service
Requires=mariadb.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/romm/backend
EnvironmentFile=/opt/romm/.env
Environment="PYTHONPATH=/opt/romm/backend"
ExecStart=/opt/romm/.venv/bin/rq worker --path /opt/romm/backend --url redis://127.0.0.1:6379/0 high default low
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/romm-scheduler.service
[Unit]
Description=RomM RQ Scheduler
After=network.target mariadb.service redis-server.service romm-backend.service
Requires=mariadb.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/romm/backend
EnvironmentFile=/opt/romm/.env
Environment="PYTHONPATH=/opt/romm/backend"
Environment="RQ_REDIS_HOST=127.0.0.1"
Environment="RQ_REDIS_PORT=6379"
ExecStart=/opt/romm/.venv/bin/rqscheduler --path /opt/romm/backend
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/romm-watcher.service
[Unit]
Description=RomM Filesystem Watcher
After=network.target romm-backend.service
Requires=romm-backend.service

[Service]
Type=simple
WorkingDirectory=/opt/romm/backend
EnvironmentFile=/opt/romm/.env
Environment="PYTHONPATH=/opt/romm/backend"
ExecStart=/opt/romm/.venv/bin/watchfiles --target-type command '/opt/romm/.venv/bin/python watcher.py' /var/lib/romm/library
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now romm-backend romm-worker romm-scheduler romm-watcher
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
