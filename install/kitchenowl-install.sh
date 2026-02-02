#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: snazzybean
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TomBursch/kitchenowl

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
  gfortran \
  pkg-config \
  ninja-build \
  autoconf \
  automake \
  libpq-dev \
  libffi-dev \
  libssl-dev \
  libpcre2-dev \
  libre2-dev \
  libxml2-dev \
  libxslt-dev \
  libopenblas-dev \
  liblapack-dev \
  zlib1g-dev \
  libjpeg62-turbo-dev \
  libsqlite3-dev \
  libexpat1-dev \
  libicu-dev
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.14" setup_uv
fetch_and_deploy_gh_release "kitchenowl" "TomBursch/kitchenowl" "tarball" "latest" "/opt/kitchenowl"
rm -rf /opt/kitchenowl/web
fetch_and_deploy_gh_release "kitchenowl-web" "TomBursch/kitchenowl" "prebuild" "latest" "/opt/kitchenowl/web" "kitchenowl_Web.tar.gz"

msg_info "Setting up KitchenOwl"
cd /opt/kitchenowl/backend
$STD uv sync --no-dev
sed -i 's/default=True/default=False/' /opt/kitchenowl/backend/wsgi.py
mkdir -p /nltk_data
$STD uv run python -m nltk.downloader -d /nltk_data averaged_perceptron_tagger_eng
JWT_SECRET=$(openssl rand -hex 32)
mkdir -p /opt/kitchenowl/data
cat <<EOF >/opt/kitchenowl/kitchenowl.env
STORAGE_PATH=/opt/kitchenowl/data
JWT_SECRET_KEY=${JWT_SECRET}
NLTK_DATA=/nltk_data
FRONT_URL=http://${LOCAL_IP}
FLASK_APP=wsgi.py
FLASK_ENV=production
EOF
set -a
source /opt/kitchenowl/kitchenowl.env
set +a
$STD uv run flask db upgrade
msg_ok "Set up KitchenOwl"

msg_info "Creating Systemd Service"
cat <<EOF >/etc/systemd/system/kitchenowl.service
[Unit]
Description=KitchenOwl Backend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/kitchenowl/backend
EnvironmentFile=/opt/kitchenowl/kitchenowl.env
ExecStart=/usr/local/bin/uv run wsgi.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now kitchenowl
msg_ok "Created and Started Service"

msg_info "Configuring Nginx"
rm -f /etc/nginx/sites-enabled/default
cat <<'EOF' >/etc/nginx/sites-available/kitchenowl.conf
server {
    listen 80;
    server_name _;

    root /opt/kitchenowl/web;
    index index.html;

    client_max_body_size 100M;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /socket.io {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        # WebSocket Timeouts - allow long-lived connections
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
EOF
ln -sf /etc/nginx/sites-available/kitchenowl.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
$STD systemctl reload nginx
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
