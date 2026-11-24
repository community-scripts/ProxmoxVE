#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/zoriya/Kyoo

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
  pkg-config \
  git \
  nginx \
  libavformat-dev \
  libavutil-dev \
  libswscale-dev
msg_ok "Installed Dependencies"

setup_ffmpeg
setup_hwaccel
PG_VERSION="18" setup_postgresql
PG_DB_NAME="kyoo" PG_DB_USER="kyoo" setup_postgresql_db
setup_go
PYTHON_VERSION="3.14" setup_uv
NODE_VERSION="24" NODE_MODULE="bun" setup_nodejs

fetch_and_deploy_gh_release "kyoo" "zoriya/Kyoo" "tarball"

msg_info "Building Kyoo Auth"
cd /opt/kyoo/auth
$STD go build -o keibi
msg_ok "Built Kyoo Auth"

msg_info "Building Kyoo Transcoder"
cd /opt/kyoo/transcoder
$STD go build -o transcoder
msg_ok "Built Kyoo Transcoder"

msg_info "Building Kyoo API"
cd /opt/kyoo/api
$STD bun install --production
$STD bun build --compile --compile-autoload-package-json --minify-whitespace --minify-syntax --target bun --outfile server ./src/index.ts
msg_ok "Built Kyoo API"

msg_info "Setting up Kyoo Scanner"
cd /opt/kyoo/scanner
$STD uv sync --locked --python 3.14
msg_ok "Set up Kyoo Scanner"

msg_info "Building Kyoo Web App"
cd /opt/kyoo/front
NODE_ENV=production $STD bun install --production
$STD bun run web
rm -rf /opt/kyoo/front/node_modules ~/.bun/install/cache
msg_ok "Built Kyoo Web App"

msg_info "Configuring Kyoo"
mkdir -p /opt/kyoo_data/{media,images,profile_pictures,metadata} /var/cache/kyoo
$STD openssl genrsa -traditional -out /opt/kyoo_data/keibi.pem 4096
SCANNER_APIKEY=$(openssl rand -hex 32)
case "${HWACCEL_VENDOR:-none}" in
nvidia) KYOO_HWACCEL="nvidia" ;;
intel | amd) KYOO_HWACCEL="vaapi" ;;
*) KYOO_HWACCEL="disabled" ;;
esac
cat <<EOF >/opt/kyoo_data/.env
PUBLIC_URL=https://${LOCAL_IP}
JWT_ISSUER=https://${LOCAL_IP}
EXTRA_OIDC_REDIRECT_URLS=kyoo

PGHOST=127.0.0.1
PGPORT=5432
PGDATABASE=kyoo
PGUSER=kyoo
PGPASSWORD=${PG_DB_PASS}
PGSSLMODE=disable

AUTH_SERVER=http://127.0.0.1:4568
JWKS_URL=http://127.0.0.1:4568/.well-known/jwks.json
TRANSCODER_SERVER=http://127.0.0.1:7666
KYOO_URL=http://127.0.0.1:8901/api
RSA_PRIVATE_KEY_PATH=/opt/kyoo_data/keibi.pem
KEIBI_APIKEY_SCANNER=${SCANNER_APIKEY}
KEIBI_APIKEY_SCANNER_CLAIMS='{"permissions": ["core.read", "core.write"]}'
KYOO_APIKEY=${SCANNER_APIKEY}

EXTRA_CLAIMS='{"permissions": ["core.read", "core.play"], "verified": false}'
FIRST_USER_CLAIMS='{"permissions": ["users.read", "users.write", "users.delete", "apikeys.read", "apikeys.write", "core.read", "core.write", "core.play", "scanner.trigger", "scanner.guess", "scanner.search", "scanner.add"], "verified": true}'
GUEST_CLAIMS='{"permissions": ["core.read"], "verified": true}'
PROTECTED_CLAIMS="permissions,verified"

SCANNER_LIBRARY_ROOT=/opt/kyoo_data/media
GOCODER_SAFE_PATH=/opt/kyoo_data/media
LIBRARY_IGNORE_PATTERN=".*/[dD]ownloads?/.*"
IMAGES_PATH=/opt/kyoo_data/images
PROFILE_PICTURE_PATH=/opt/kyoo_data/profile_pictures
GOCODER_METADATA_ROOT=/opt/kyoo_data/metadata
GOCODER_CACHE_ROOT=/var/cache/kyoo
GOCODER_HWACCEL=${KYOO_HWACCEL}
GOCODER_PRESET=fast

THEMOVIEDB_API_ACCESS_TOKEN=
TVDB_APIKEY=
TVDB_PIN=
EOF
chmod 600 /opt/kyoo_data/.env /opt/kyoo_data/keibi.pem
msg_ok "Configured Kyoo"

msg_info "Configuring Nginx"
create_self_signed_cert "kyoo"
# Upstream's Traefik routes; auth_request replaces its forwardAuth that swaps tokens/API keys for a JWT.
# HTTPS so browsers honour COOP/COEP (SharedArrayBuffer for subtitles); 127.0.0.1:8901 is plain HTTP for the scanner.
cat <<'EOF' >/etc/nginx/sites-available/kyoo
map $http_upgrade $kyoo_connection_upgrade {
    default upgrade;
    ''      close;
}

map $http_x_forwarded_proto $kyoo_forwarded_proto {
    default $http_x_forwarded_proto;
    ''      $scheme;
}

map $http_x_forwarded_host $kyoo_forwarded_host {
    default $http_x_forwarded_host;
    ''      $http_host;
}

server {
    listen 80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl default_server;
    listen 127.0.0.1:8901;
    server_name _;
    charset utf-8;
    client_max_body_size 0;

    ssl_certificate /etc/ssl/kyoo/kyoo.crt;
    ssl_certificate_key /etc/ssl/kyoo/kyoo.key;

    root /opt/kyoo/front/dist;
    index index.html;

    location / {
        add_header Cross-Origin-Opener-Policy same-origin;
        add_header Cross-Origin-Embedder-Policy credentialless;
        try_files $uri $uri/ /index.html;
    }

    location = /_kyoo_jwt {
        internal;
        proxy_pass http://127.0.0.1:4568/auth/jwt;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Forwarded-Method $request_method;
        proxy_set_header X-Forwarded-Uri $request_uri;
        proxy_set_header X-Forwarded-Host $kyoo_forwarded_host;
        proxy_set_header X-Forwarded-Proto $kyoo_forwarded_proto;
    }

    location /auth/ {
        proxy_pass http://127.0.0.1:4568;
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $kyoo_forwarded_host;
        proxy_set_header X-Forwarded-Proto $kyoo_forwarded_proto;
    }

    location /.well-known/ {
        proxy_pass http://127.0.0.1:4568;
    }

    location /swagger {
        proxy_pass http://127.0.0.1:3567;
    }

    location /api/ {
        if ($request_method = OPTIONS) {
            add_header Access-Control-Allow-Origin * always;
            add_header Access-Control-Allow-Methods "GET, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, Range, X-Api-Key" always;
            add_header Vary Origin always;
            return 204;
        }
        add_header Access-Control-Allow-Origin * always;
        add_header Vary Origin always;
        auth_request /_kyoo_jwt;
        auth_request_set $kyoo_jwt $upstream_http_authorization;
        proxy_pass http://127.0.0.1:3567;
        proxy_http_version 1.1;
        proxy_read_timeout 1h;
        proxy_set_header Authorization $kyoo_jwt;
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $kyoo_forwarded_host;
        proxy_set_header X-Forwarded-Proto $kyoo_forwarded_proto;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $kyoo_connection_upgrade;
    }

    location /video {
        if ($request_method = OPTIONS) {
            add_header Access-Control-Allow-Origin * always;
            add_header Access-Control-Allow-Methods "GET, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, Range, X-Api-Key" always;
            add_header Vary Origin always;
            return 204;
        }
        add_header Access-Control-Allow-Origin * always;
        add_header Vary Origin always;
        auth_request /_kyoo_jwt;
        auth_request_set $kyoo_jwt $upstream_http_authorization;
        proxy_pass http://127.0.0.1:7666;
        proxy_http_version 1.1;
        proxy_buffering off;
        proxy_read_timeout 1h;
        proxy_set_header Authorization $kyoo_jwt;
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $kyoo_forwarded_host;
        proxy_set_header X-Forwarded-Proto $kyoo_forwarded_proto;
    }

    location /scanner/ {
        auth_request /_kyoo_jwt;
        auth_request_set $kyoo_jwt $upstream_http_authorization;
        proxy_pass http://127.0.0.1:4389;
        proxy_set_header Authorization $kyoo_jwt;
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $kyoo_forwarded_host;
        proxy_set_header X-Forwarded-Proto $kyoo_forwarded_proto;
    }
}
EOF
nginx_enable_site "kyoo"
msg_ok "Configured Nginx"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/kyoo-auth.service
[Unit]
Description=Kyoo Auth
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/kyoo/auth
EnvironmentFile=/opt/kyoo_data/.env
ExecStart=/opt/kyoo/auth/keibi
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/kyoo-transcoder.service
[Unit]
Description=Kyoo Transcoder
After=network.target postgresql.service kyoo-auth.service
Requires=postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/kyoo/transcoder
EnvironmentFile=/opt/kyoo_data/.env
ExecStart=/opt/kyoo/transcoder/transcoder
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/kyoo-api.service
[Unit]
Description=Kyoo API
After=network.target postgresql.service kyoo-auth.service
Requires=postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/kyoo/api
EnvironmentFile=/opt/kyoo_data/.env
Environment=NODE_ENV=production
ExecStart=/opt/kyoo/api/server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/kyoo-scanner.service
[Unit]
Description=Kyoo Scanner
After=network.target postgresql.service nginx.service kyoo-api.service
Requires=postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/kyoo/scanner
EnvironmentFile=/opt/kyoo_data/.env
ExecStart=/opt/kyoo/scanner/.venv/bin/fastapi run scanner --host 127.0.0.1 --port 4389
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now kyoo-auth kyoo-transcoder kyoo-api kyoo-scanner
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
