#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://shlink.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.5" setup_php
setup_mariadb
MARIADB_DB_NAME="shlink" MARIADB_DB_USER="shlink" setup_mariadb_db

fetch_and_deploy_gh_release "shlink" "shlinkio/shlink" "prebuild" "latest" "/opt/shlink" "shlink*_php8.5_dist.zip"

msg_info "Setting up Application"
cd /opt/shlink
$STD php ./vendor/bin/rr get --no-interaction --location bin/
chmod +x bin/rr
mkdir -p data/cache data/locks data/log data/proxies data/temp-geolite
chmod -R 775 data
cat <<EOF >/opt/shlink/.env
DEFAULT_DOMAIN=${LOCAL_IP}:8080
IS_HTTPS_ENABLED=false
DB_DRIVER=maria
DB_NAME=${MARIADB_DB_NAME}
DB_USER=${MARIADB_DB_USER}
DB_PASSWORD=${MARIADB_DB_PASS}
DB_HOST=127.0.0.1
DB_PORT=3306
EOF
set -a
source /opt/shlink/.env
set +a
$STD php vendor/bin/shlink-installer init --no-interaction --clear-db-cache --skip-download-geolite
API_OUTPUT=$(php bin/cli api-key:generate --name=default 2>&1)
INITIAL_API_KEY=$(echo "$API_OUTPUT" | sed -n 's/.*Generated API key: "\([^"]*\)".*/\1/p')
if [[ -n "$INITIAL_API_KEY" ]]; then
  echo "INITIAL_API_KEY=${INITIAL_API_KEY}" >>/opt/shlink/.env
fi
msg_ok "Set up Application"

if prompt_confirm "Install Shlink Web Client?" "y" 60; then
  msg_info "Installing Dependencies"
  $STD apt install -y nginx
  msg_ok "Installed Dependencies"

  fetch_and_deploy_gh_release "shlink-web-client" "shlinkio/shlink-web-client" "prebuild" "latest" "/opt/shlink-web-client" "shlink-web-client_*_dist.zip"

  msg_info "Setting up Web Client"
  cat <<EOF >/opt/shlink-web-client/servers.json
[
  {
    "name": "Shlink",
    "url": "http://${LOCAL_IP}:8080",
    "apiKey": "${INITIAL_API_KEY}"
  }
]
EOF
  cat <<'EOF' >/etc/nginx/sites-available/shlink-web-client
server {
    listen 3000 default_server;
    charset utf-8;
    root /opt/shlink-web-client;
    index index.html;

    location ~* \.(?:manifest|appcache|html?|xml|json)$ {
        expires -1;
    }

    location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc)$ {
        expires 1M;
        add_header Cache-Control "public";
    }

    location ~* \.(?:css|js)$ {
        expires 1y;
        add_header Cache-Control "public";
    }

    location = /servers.json {
        try_files /servers.json /conf.d/servers.json;
    }

    location / {
        try_files $uri $uri/ /index.html$is_args$args;
    }
}
EOF
  ln -sf /etc/nginx/sites-available/shlink-web-client /etc/nginx/sites-enabled/shlink-web-client
  rm -f /etc/nginx/sites-enabled/default
  systemctl enable -q nginx
  $STD systemctl restart nginx
  msg_ok "Set up Web Client"
fi

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/shlink.service
[Unit]
Description=Shlink URL Shortener
After=network.target mariadb.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/shlink
EnvironmentFile=/opt/shlink/.env
ExecStart=/opt/shlink/bin/rr serve -c config/roadrunner/.rr.yml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now shlink
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
