#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://portabase.io

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
  nginx
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="pnpm@11.8.0" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_NAME="portabase" PG_DB_USER="portabase" setup_postgresql_db

fetch_and_deploy_gh_release "portabase" "Portabase/portabase" "tarball"
fetch_and_deploy_gh_release "tusd" "tus/tusd" "prebuild" "latest" "/opt/tusd" "tusd_linux_$(arch_resolve).tar.gz"

msg_info "Configuring Portabase"
mkdir -p /opt/portabase-data/uploads/tmp
mv -f "/opt/tusd/tusd_linux_$(arch_resolve)/tusd" /opt/tusd/tusd
rm -rf "/opt/tusd/tusd_linux_$(arch_resolve)"
chmod +x /opt/tusd/tusd
PROJECT_SECRET=$(openssl rand -hex 32)
ADMIN_PASSWORD=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | head -c 16)
cat <<EOF >/opt/portabase/.env
LOG_LEVEL=info
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}
PROJECT_NAME=Portabase
PROJECT_URL=http://${LOCAL_IP}:3000
PROJECT_SECRET=${PROJECT_SECRET}
TRUSTED_DOMAINS=http://${LOCAL_IP}:3000
PRIVATE_PATH=/opt/portabase-data
AUTH_DEFAULT_USER_NAME=Portabase Admin
AUTH_DEFAULT_USER=admin@example.com
AUTH_DEFAULT_PASSWORD=${ADMIN_PASSWORD}
AUTH_EMAIL_PASSWORD_ENABLED=true
AUTH_SIGNUP_ENABLED=true
RETENTION_CRON=0 7 * * *
TUSD_BEHIND_PROXY=true
TELEMETRY=false
EOF
cat <<EOF >~/portabase.creds
Portabase Admin
Username: admin@example.com
Password: ${ADMIN_PASSWORD}
EOF
msg_ok "Configured Portabase"

msg_info "Building Portabase"
cd /opt/portabase
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export NEXT_TELEMETRY_DISABLED=1
$STD pnpm install --frozen-lockfile
$STD pnpm run build
cp -r /opt/portabase/.next/static /opt/portabase/.next/standalone/.next/static
cp -r /opt/portabase/public /opt/portabase/.next/standalone/public
mkdir -p /opt/portabase/.next/standalone/src/db
cp -r /opt/portabase/src/db/migrations /opt/portabase/.next/standalone/src/db/migrations
ln -sf /opt/portabase/.env /opt/portabase/.next/standalone/.env
msg_ok "Built Portabase"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/portabase-tusd.service
[Unit]
Description=Portabase tusd Upload Server
After=network.target
Before=portabase.service

[Service]
Type=simple
ExecStart=/opt/tusd/tusd --base-path /tus/files/ --upload-dir /opt/portabase-data/uploads/tmp --hooks-http http://127.0.0.1:8887/api/tus/hooks --port 1080 --max-size 21474836480 --behind-proxy
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/portabase.service
[Unit]
Description=Portabase
After=network.target postgresql.service portabase-tusd.service
Wants=postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/portabase/.next/standalone
Environment=NODE_ENV=production
Environment=PORT=8887
Environment=HOSTNAME=127.0.0.1
ExecStart=/usr/bin/node /opt/portabase/.next/standalone/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now portabase-tusd portabase
msg_ok "Created Services"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/portabase
map $http_x_forwarded_proto $forwarded_proto {
    default $scheme;
    "~*^\s*(https?)\s*(?:,|$)" $1;
}

server {
    listen 3000;
    server_name _;

    client_max_body_size 20G;
    ignore_invalid_headers off;

    location /tus/ {
        proxy_pass http://127.0.0.1:1080/tus/;
        proxy_pass_request_headers on;
        proxy_request_buffering off;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-Proto $forwarded_proto;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location = /api/tus/hooks {
        deny all;
        return 404;
    }

    location / {
        proxy_pass http://127.0.0.1:8887;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-Proto $forwarded_proto;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF
nginx_enable_site portabase
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
