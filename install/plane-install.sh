#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: onionrings29
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://plane.so

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
    build-essential \
    libpq-dev \
    libxml2-dev \
    libxslt1-dev \
    libxmlsec1-dev \
    libxmlsec1-openssl \
    pkg-config \
    python3-dev \
    python3-venv \
    redis-server \
    erlang-base \
    erlang-{asn1,crypto,eldap,ftp,inets,mnesia,os-mon,parsetools} \
    erlang-{public-key,runtime-tools,snmp,ssl,syntax-tools,tftp,tools,xmerl} \
    rabbitmq-server
msg_ok "Installed Dependencies"

NODE_VERSION="24" NODE_MODULE="corepack" setup_nodejs
PG_VERSION="16" setup_postgresql
PG_DB_NAME="plane" PG_DB_USER="plane" setup_postgresql_db

msg_info "Configuring RabbitMQ"
RABBITMQ_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c16)
$STD rabbitmqctl add_vhost plane
$STD rabbitmqctl add_user plane "${RABBITMQ_PASS}"
$STD rabbitmqctl set_permissions -p plane plane ".*" ".*" ".*"
msg_ok "Configured RabbitMQ"

msg_info "Installing Garage"
ensure_dependencies jq
GARAGE_RELEASE=$(curl -fsSL https://api.github.com/repos/deuxfleurs-org/garage/tags | jq -r '.[0].name')
curl -fsSL "https://garagehq.deuxfleurs.fr/_releases/${GARAGE_RELEASE}/$(arch_resolve "x86_64" "aarch64")-unknown-linux-musl/garage" -o /usr/local/bin/garage
chmod +x /usr/local/bin/garage
mkdir -p /var/lib/garage/{data,meta,snapshots}
S3_ACCESS_KEY="GK$(openssl rand -hex 16)"
S3_SECRET_KEY=$(openssl rand -hex 32)
GARAGE_RPC_SECRET=$(openssl rand -hex 32)
cat <<EOF >/etc/garage.toml
metadata_dir = "/var/lib/garage/meta"
data_dir = "/var/lib/garage/data"
db_engine = "sqlite"
replication_factor = 1

rpc_bind_addr = "127.0.0.1:3901"
rpc_public_addr = "127.0.0.1:3901"
rpc_secret = "${GARAGE_RPC_SECRET}"

[s3_api]
s3_region = "us-east-1"
api_bind_addr = "127.0.0.1:3900"
EOF
cat <<EOF >/etc/default/garage
GARAGE_DEFAULT_ACCESS_KEY=${S3_ACCESS_KEY}
GARAGE_DEFAULT_SECRET_KEY=${S3_SECRET_KEY}
GARAGE_DEFAULT_BUCKET=uploads
EOF
cat <<EOF >/etc/systemd/system/garage.service
[Unit]
Description=Garage Object Storage
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
EnvironmentFile=/etc/default/garage
ExecStart=/usr/local/bin/garage -c /etc/garage.toml server --single-node --default-bucket
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now garage
for i in {1..30}; do
    curl -s -o /dev/null "http://127.0.0.1:3900" && break
    if [[ $i -eq 30 ]]; then
        msg_error "Garage did not become ready"
        exit 1
    fi
    sleep 1
done
msg_ok "Installed Garage"

fetch_and_deploy_gh_release "plane" "makeplane/plane" "tarball"

msg_info "Building Frontend Apps (Patience)"
cd /opt/plane
FRONTEND_ENV="VITE_API_BASE_URL=http://${LOCAL_IP}
VITE_WEB_BASE_URL=http://${LOCAL_IP}
VITE_ADMIN_BASE_URL=http://${LOCAL_IP}
VITE_ADMIN_BASE_PATH=/god-mode
VITE_SPACE_BASE_URL=http://${LOCAL_IP}
VITE_SPACE_BASE_PATH=/spaces
VITE_LIVE_BASE_URL=http://${LOCAL_IP}
VITE_LIVE_BASE_PATH=/live"
# Each Vite app needs its own .env for the build
for frontend_app in web admin space; do
    echo "$FRONTEND_ENV" >/opt/plane/apps/${frontend_app}/.env
done
export NODE_OPTIONS="--max-old-space-size=4096"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

$STD pnpm install --frozen-lockfile
$STD pnpm turbo run build --filter=web --filter=admin --filter=space --filter=live
msg_ok "Built Frontend Apps"

msg_info "Setting up Python API"
setup_uv
$STD uv venv /opt/plane-venv
export VIRTUAL_ENV=/opt/plane-venv
$STD uv pip install -r /opt/plane/apps/api/requirements/production.txt
msg_ok "Set up Python API"

msg_info "Configuring Plane"
SECRET_KEY=$(openssl rand -hex 32)
MACHINE_SIG=$(echo -n "$(hostname)-$(date +%s)" | sha256sum | head -c64)
LIVE_SECRET=$(openssl rand -hex 16)
cat <<EOF >/opt/plane/apps/api/.env
DEBUG=0
CORS_ALLOWED_ORIGINS=http://${LOCAL_IP}

POSTGRES_USER=plane
POSTGRES_PASSWORD=${PG_DB_PASS}
POSTGRES_HOST=localhost
POSTGRES_DB=plane
POSTGRES_PORT=5432
DATABASE_URL=postgresql://plane:${PG_DB_PASS}@localhost:5432/plane

REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_URL=redis://localhost:6379/

RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=plane
RABBITMQ_PASSWORD=${RABBITMQ_PASS}
RABBITMQ_VHOST=plane
AMQP_URL=amqp://plane:${RABBITMQ_PASS}@localhost:5672/plane

AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=${S3_ACCESS_KEY}
AWS_SECRET_ACCESS_KEY=${S3_SECRET_KEY}
AWS_S3_ENDPOINT_URL=http://localhost:3900
AWS_S3_BUCKET_NAME=uploads
FILE_SIZE_LIMIT=104857600

USE_MINIO=1
MINIO_ENDPOINT_SSL=0
SECRET_KEY=${SECRET_KEY}
MACHINE_SIGNATURE=${MACHINE_SIG}

WEB_URL=http://${LOCAL_IP}
ADMIN_BASE_URL=http://${LOCAL_IP}
ADMIN_BASE_PATH=/god-mode
SPACE_BASE_URL=http://${LOCAL_IP}
SPACE_BASE_PATH=/spaces
APP_BASE_URL=http://${LOCAL_IP}
APP_BASE_PATH=
LIVE_BASE_URL=http://${LOCAL_IP}
LIVE_BASE_PATH=/live

GUNICORN_WORKERS=2
LIVE_SERVER_SECRET_KEY=${LIVE_SECRET}
API_KEY_RATE_LIMIT=60/minute
EOF
cat <<EOF >/opt/plane/.env
API_BASE_URL=http://localhost:8000
LIVE_SERVER_SECRET_KEY=${LIVE_SECRET}
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_URL=redis://localhost:6379/
PORT=3100
EOF
msg_ok "Configured Plane"

msg_info "Running Database Migrations"
cd /opt/plane/apps/api
set -a
source /opt/plane/apps/api/.env
set +a
$STD /opt/plane-venv/bin/python manage.py migrate
$STD /opt/plane-venv/bin/python manage.py collectstatic --noinput
$STD /opt/plane-venv/bin/python manage.py configure_instance
$STD /opt/plane-venv/bin/python manage.py register_instance "${MACHINE_SIG}"
msg_ok "Ran Database Migrations"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/plane-api.service
[Unit]
Description=Plane API
After=network.target postgresql.service redis-server.service rabbitmq-server.service garage.service

[Service]
Type=simple
WorkingDirectory=/opt/plane/apps/api
EnvironmentFile=/opt/plane/apps/api/.env
ExecStart=/opt/plane-venv/bin/gunicorn -w 2 -k uvicorn.workers.UvicornWorker plane.asgi:application --bind 0.0.0.0:8000 --max-requests 1200 --max-requests-jitter 1000 --access-logfile -
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/plane-worker.service
[Unit]
Description=Plane Celery Worker
After=plane-api.service
Requires=plane-api.service

[Service]
Type=simple
WorkingDirectory=/opt/plane/apps/api
EnvironmentFile=/opt/plane/apps/api/.env
ExecStart=/opt/plane-venv/bin/celery -A plane worker -l info
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/plane-beat.service
[Unit]
Description=Plane Celery Beat
After=plane-api.service
Requires=plane-api.service

[Service]
Type=simple
WorkingDirectory=/opt/plane/apps/api
EnvironmentFile=/opt/plane/apps/api/.env
ExecStart=/opt/plane-venv/bin/celery -A plane beat -l info
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/plane-live.service
[Unit]
Description=Plane Live Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/plane
EnvironmentFile=/opt/plane/.env
ExecStart=/usr/bin/node apps/live/dist/start.mjs
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/plane-space.service
[Unit]
Description=Plane Space Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/plane/apps/space
Environment=PORT=3002
Environment=NODE_ENV=production
ExecStart=/opt/plane/apps/space/node_modules/.bin/react-router-serve ./build/server/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q --now plane-api plane-worker plane-beat plane-live plane-space
cat <<EOF >~/plane.creds
RabbitMQ User: plane
RabbitMQ Password: ${RABBITMQ_PASS}
S3 Access Key: ${S3_ACCESS_KEY}
S3 Secret Key: ${S3_SECRET_KEY}
Secret Key: ${SECRET_KEY}
Config: /opt/plane/apps/api/.env
EOF
msg_ok "Created Services"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/plane.conf
upstream plane-api {
    server 127.0.0.1:8000;
}

upstream plane-live {
    server 127.0.0.1:3100;
}

upstream plane-space {
    server 127.0.0.1:3002;
}

upstream plane-garage {
    server 127.0.0.1:3900;
}

server {
    listen 80 default_server;
    server_name _;
    client_max_body_size 100M;

    location /api/ {
        proxy_pass http://plane-api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /auth/ {
        proxy_pass http://plane-api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /opt/plane/apps/api/plane/static-assets/collected-static/;
    }

    location /live/ {
        proxy_pass http://plane-live;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location = /uploads {
        proxy_pass http://plane-garage;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /uploads/ {
        proxy_pass http://plane-garage;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /spaces/ {
        proxy_pass http://plane-space;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /spaces {
        return 301 /spaces/;
    }

    location /god-mode/ {
        alias /opt/plane/apps/admin/build/client/;
        try_files $uri $uri/ /god-mode/index.html;
    }

    location /god-mode {
        return 301 /god-mode/;
    }

    location / {
        root /opt/plane/apps/web/build/client;
        try_files $uri $uri/ /index.html;
    }
}
EOF
nginx_enable_site plane.conf
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
