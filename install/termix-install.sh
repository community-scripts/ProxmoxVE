#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Termix-SSH/Termix

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  build-essential \
  python3 \
  make \
  g++ \
  nginx \
  openssl \
  gettext-base
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "termix" "Termix-SSH/Termix"

msg_info "Building Frontend"
cd /opt/termix
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
find public/fonts -name "*.ttf" ! -name "*Regular.ttf" ! -name "*Bold.ttf" ! -name "*Italic.ttf" -delete 2>/dev/null || true
$STD npm install --ignore-scripts --force
$STD npm cache clean --force
$STD npm run build
msg_ok "Built Frontend"

msg_info "Building Backend"
$STD npm rebuild better-sqlite3 --force
$STD npm run build:backend
msg_ok "Built Backend"

msg_info "Setting up Node Dependencies"
cd /opt/termix
$STD npm ci --only=production --ignore-scripts --force
$STD npm rebuild better-sqlite3 bcryptjs --force
$STD npm cache clean --force
msg_ok "Set up Node Dependencies"

msg_info "Setting up Directories"
mkdir -p /opt/termix/data \
  /opt/termix/uploads \
  /opt/termix/html \
  /opt/termix/nginx \
  /opt/termix/nginx/logs \
  /opt/termix/nginx/cache \
  /opt/termix/nginx/client_body

cp -r /opt/termix/dist/* /opt/termix/html/ 2>/dev/null || true
cp -r /opt/termix/src/locales /opt/termix/html/locales 2>/dev/null || true
cp -r /opt/termix/public/fonts /opt/termix/html/fonts 2>/dev/null || true
msg_ok "Set up Directories"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/termix.conf
error_log /opt/termix/nginx/logs/error.log warn;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log /opt/termix/nginx/logs/access.log;

    client_body_temp_path /opt/termix/nginx/client_body;
    proxy_temp_path /opt/termix/nginx/proxy_temp;

    sendfile on;
    keepalive_timeout 65;
    client_header_timeout 300s;

    server {
        listen 80;
        server_name _;

        add_header X-Content-Type-Options nosniff always;
        add_header X-XSS-Protection "1; mode=block" always;

        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            root /opt/termix/html;
            expires 1y;
            add_header Cache-Control "public, immutable";
            try_files $uri =404;
        }

        location / {
            root /opt/termix/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }

        location ~ ^/users(/.*)?$ {
            proxy_pass http://127.0.0.1:30001;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location ~ ^/(version|releases|alerts|rbac|credentials|snippets|terminal|encryption)(/.*)?$ {
            proxy_pass http://127.0.0.1:30001;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location ~ ^/(database|db)(/.*)?$ {
            client_max_body_size 5G;
            client_body_timeout 300s;
            proxy_pass http://127.0.0.1:30001;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_connect_timeout 60s;
            proxy_send_timeout 300s;
            proxy_read_timeout 300s;
            proxy_request_buffering off;
            proxy_buffering off;
        }

        location /ssh/ {
            proxy_pass http://127.0.0.1:30001;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /ssh/websocket/ {
            proxy_pass http://127.0.0.1:30002/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
            proxy_buffering off;
            proxy_request_buffering off;
        }

        location /ssh/tunnel/ {
            proxy_pass http://127.0.0.1:30003;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /ssh/file_manager/ssh/ {
            client_max_body_size 5G;
            client_body_timeout 300s;
            proxy_pass http://127.0.0.1:30004;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_connect_timeout 60s;
            proxy_send_timeout 300s;
            proxy_read_timeout 300s;
            proxy_request_buffering off;
            proxy_buffering off;
        }

        location ~ ^/ssh/file_manager/(recent|pinned|shortcuts)$ {
            proxy_pass http://127.0.0.1:30001;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /health {
            proxy_pass http://127.0.0.1:30001;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
        }

        location ~ ^/(status|metrics)(/.*)?$ {
            proxy_pass http://127.0.0.1:30005;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location ~ ^/(uptime|activity)(/.*)?$ {
            proxy_pass http://127.0.0.1:30006;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location ^~ /docker/console/ {
            proxy_pass http://127.0.0.1:30008/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
            proxy_buffering off;
            proxy_request_buffering off;
        }

        location ~ ^/docker(/.*)?$ {
            proxy_pass http://127.0.0.1:30007;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_connect_timeout 60s;
            proxy_send_timeout 300s;
            proxy_read_timeout 300s;
        }
    }
}
EOF
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/nginx.conf
ln -sf /etc/nginx/sites-available/termix.conf /etc/nginx/nginx.conf
systemctl reload nginx
msg_ok "Configured Nginx"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/termix.service
[Unit]
Description=Termix Backend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/termix
Environment=NODE_ENV=production
Environment=DATA_DIR=/opt/termix/data
ExecStart=/usr/bin/node /opt/termix/dist/backend/backend/starter.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now termix
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
