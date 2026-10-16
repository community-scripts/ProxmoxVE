#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DuarteSantos8/openGym

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "opengym" "DuarteSantos8/openGym" "tarball" "latest" "/opt/opengym" "" "v"

msg_info "Building openGym"
cd /opt/opengym/api
$STD npm ci --omit=dev --omit=optional
cd /opt/opengym/frontend
# Like upstream's web/Dockerfile: skips sharp's libvips download, which only draws the mobile app icons
$STD npm ci --ignore-scripts
$STD npm run build
rm -rf /opt/opengym/frontend/node_modules ~/.npm
msg_ok "Built openGym"

msg_info "Configuring openGym"
mkdir -p /opt/opengym_data
cat <<EOF >/opt/opengym_data/.env
PORT=3000
DATA_DIR=/opt/opengym_data
RP_NAME=openGym
# Passkeys need HTTPS on a hostname. Behind a reverse proxy set both to the address in the browser,
# e.g. RP_ID=gym.example.com and ORIGIN=https://gym.example.com, then: systemctl restart opengym
RP_ID=${LOCAL_IP}
ORIGIN=http://${LOCAL_IP}
PASSWORD_LOGIN=1
FIRST_USER_ADMIN=1
EOF
chmod 600 /opt/opengym_data/.env
msg_ok "Configured openGym"

msg_info "Creating openGym Service"
cat <<EOF >/etc/systemd/system/opengym.service
[Unit]
Description=openGym API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/opengym/api
EnvironmentFile=/opt/opengym_data/.env
Environment=NODE_ENV=production
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now opengym
msg_ok "Created openGym Service"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/opengym
server {
    listen 80 default_server;
    server_name _;
    root /opt/opengym/frontend/dist;
    index index.html;
    absolute_redirect off;

    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "same-origin" always;
    add_header Content-Security-Policy "frame-ancestors 'none'" always;

    location ^~ /api/ {
        client_max_body_size 5m;
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header CF-Connecting-IP "";
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }

    location ^~ /api/media/ {
        client_max_body_size 48m;
        proxy_request_buffering off;
        proxy_buffering off;
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header CF-Connecting-IP "";
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }

    location / {
        try_files $uri $uri/ @root;
    }

    location @root {
        return 302 /$is_args$args;
    }

    location ~* \.(js|css|json|html)$ {
        add_header Cache-Control "no-cache, must-revalidate";
        add_header X-Frame-Options "DENY" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "same-origin" always;
        add_header Content-Security-Policy "frame-ancestors 'none'" always;
    }

    location ^~ /exercise-media/ {
        alias /opt/opengym/catalogue/media/;
        add_header Cache-Control "public, max-age=2592000, immutable";
        add_header Cross-Origin-Resource-Policy "same-origin" always;
        add_header X-Frame-Options "DENY" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "same-origin" always;
        add_header Content-Security-Policy "frame-ancestors 'none'" always;
    }

    location ~* \.(png|jpg|jpeg|gif|ico|svg|woff|woff2|webp|avif|mp4)$ {
        add_header Cache-Control "public, max-age=2592000, immutable";
        add_header X-Frame-Options "DENY" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "same-origin" always;
        add_header Content-Security-Policy "frame-ancestors 'none'" always;
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript image/svg+xml;
    gzip_vary on;
    gzip_min_length 1024;
}
EOF
nginx_enable_site "opengym"
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
