#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/alam00000/bentopdf

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
  openssl
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs
fetch_and_deploy_gh_release "bentopdf" "alam00000/bentopdf" "tarball" "latest" "/opt/bentopdf"

msg_info "Setup BentoPDF"
cd /opt/bentopdf
$STD npm ci --no-audit --no-fund
cp ./.env.example ./.env.production
export NODE_OPTIONS="--max-old-space-size=3072"
export SIMPLE_MODE=true
export VITE_USE_CDN=true
$STD npm run build:all
cat <<'EOF' >/opt/bentopdf/dist/config.json
{}
EOF
msg_ok "Setup BentoPDF"

msg_info "Creating Service"
CERT_CN="$(hostname -I | awk '{print $1}')"
$STD openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
  -keyout /etc/ssl/private/bentopdf-selfsigned.key \
  -out /etc/ssl/certs/bentopdf-selfsigned.crt \
  -subj "/CN=${CERT_CN}"

cat <<'EOF' >/etc/nginx/sites-available/bentopdf
server {
    listen 8080;
    server_name _;
    return 301 https://$host:8443$request_uri;
}

server {
    listen 8443 ssl;
    server_name _;
    ssl_certificate /etc/ssl/certs/bentopdf-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/bentopdf-selfsigned.key;
    root /opt/bentopdf/dist;
    index index.html;

    # Required for LibreOffice WASM (Word/Excel/PowerPoint to PDF via SharedArrayBuffer)
    add_header Cross-Origin-Opener-Policy "same-origin" always;
    add_header Cross-Origin-Embedder-Policy "require-corp" always;
    add_header Cross-Origin-Resource-Policy "cross-origin" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;

    gzip_static on;

    location ~* /libreoffice-wasm/soffice\.wasm\.gz$ {
        gzip off;
        types {} default_type application/wasm;
        add_header Content-Encoding gzip;
        add_header Vary "Accept-Encoding";
        add_header Cache-Control "public, immutable";
    }

    location ~* /libreoffice-wasm/soffice\.data\.gz$ {
        gzip off;
        types {} default_type application/octet-stream;
        add_header Content-Encoding gzip;
        add_header Vary "Accept-Encoding";
        add_header Cache-Control "public, immutable";
    }

    location ~* \.wasm$ {
        types {} default_type application/wasm;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location ~* \.(wasm\.gz|data\.gz|data)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location / {
        try_files $uri $uri/ $uri.html =404;
    }

    error_page 404 /404.html;
}
EOF
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/bentopdf /etc/nginx/sites-enabled/bentopdf
systemctl stop nginx
systemctl disable -q nginx
sed -i '/application\/rss+xml/a\    application\/javascript                           mjs;' /etc/nginx/mime.types

cat <<'EOF' >/etc/systemd/system/bentopdf.service
[Unit]
Description=BentoPDF Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/nginx -g "daemon off;"
ExecReload=/bin/kill -HUP $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now bentopdf
msg_ok "Created & started service"

motd_ssh
customize
cleanup_lxc
