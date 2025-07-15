#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01 | CanbiZ
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/karlomikus/bar-assistant
# Source: https://github.com/karlomikus/vue-salt-rim
# Source: https://www.meilisearch.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  redis-server \
  nginx \
  lsb-release \
  libvips
#php-{ffi,opcache,redis,zip,pdo-sqlite,bcmath,pdo,curl,dom,fpm}
msg_ok "Installed Dependencies"

PHP_VERSION="8.3" PHP_FPM=YES PHP_MODULE="ffi,opcache,redis,zip,pdo-sqlite,bcmath,pdo,curl,dom,fpm" setup_php
setup_composer
NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "meilisearch" "meilisearch/meilisearch" "binary"
fetch_and_deploy_gh_release "bar-assistant" "karlomikus/bar-assistant" "tarball" "latest" "/opt/bar-assistant"
fetch_and_deploy_gh_release "vue-salt-rim" "karlomikus/vue-salt-rim" "tarball" "latest" "/opt/vue-salt-rim"

msg_info "Configuring PHP"
PHPVER=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION . "\n";')
sed -i.bak -E 's/^\s*;?\s*ffi\.enable\s*=.*/ffi.enable=true/' /etc/php/${PHPVER}/fpm/php.ini
$STD systemctl reload php${PHPVER}-fpm
msg_info "configured PHP"

msg_info "Configure MeiliSearch"
curl -fsSL https://raw.githubusercontent.com/meilisearch/meilisearch/latest/config.toml -o /etc/meilisearch.toml
MASTER_KEY=$(openssl rand -base64 12)
sed -i \
  -e 's|^env =.*|env = "production"|' \
  -e "s|^# master_key =.*|master_key = \"$MASTER_KEY\"|" \
  -e 's|^db_path =.*|db_path = "/var/lib/meilisearch/data"|' \
  -e 's|^dump_dir =.*|dump_dir = "/var/lib/meilisearch/dumps"|' \
  -e 's|^snapshot_dir =.*|snapshot_dir = "/var/lib/meilisearch/snapshots"|' \
  -e 's|^# no_analytics = true|no_analytics = true|' \
  -e 's|^http_addr =.*|http_addr = "127.0.0.1:7700"|' \
  /etc/meilisearch.toml
msg_ok "Configured MeiliSearch"

msg_info "Creating MeiliSearch service"
cat <<EOF >/etc/systemd/system/meilisearch.service
[Unit]
Description=Meilisearch
After=network.target

[Service]
ExecStart=/usr/bin/meilisearch --config-file-path /etc/meilisearch.toml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now meilisearch
sleep 5
msg_ok "Created Service MeiliSearch"

msg_info "Installing Bar Assistant"
cd /opt/bar-assistant
cp /opt/bar-assistant/.env.dist /opt/bar-assistant/.env
MeiliSearch_API_KEY=$(curl -s -X GET 'http://127.0.0.1:7700/keys' -H "Authorization: Bearer $MASTER_KEY" | grep -o '"key":"[^"]*"' | head -n 1 | sed 's/"key":"//;s/"//')
MeiliSearch_API_KEY_UID=$(curl -s -X GET 'http://127.0.0.1:7700/keys' -H "Authorization: Bearer $MASTER_KEY" | grep -o '"uid":"[^"]*"' | head -n 1 | sed 's/"uid":"//;s/"//')
LOCAL_IP=$(hostname -I | awk '{print $1}')
sed -i -e "s|^APP_URL=|APP_URL=http://${LOCAL_IP}/bar/|" \
  -e "s|^MEILISEARCH_HOST=|MEILISEARCH_HOST=http://127.0.0.1:7700|" \
  -e "s|^MEILISEARCH_KEY=|MEILISEARCH_KEY=${MASTER_KEY}|" \
  -e "s|^MEILISEARCH_API_KEY=|MEILISEARCH_API_KEY=${MeiliSearch_API_KEY}|" \
  -e "s|^MEILISEARCH_API_KEY_UID=|MEILISEARCH_API_KEY_UID=${MeiliSearch_API_KEY_UID}|" \
  /opt/bar-assistant/.env
$STD composer install --no-interaction
$STD php artisan key:generate
touch storage/bar-assistant/database.ba3.sqlite
$STD php artisan migrate --force
$STD php artisan storage:link
$STD php artisan bar:setup-meilisearch
$STD php artisan scout:sync-index-settings
$STD php artisan config:cache
$STD php artisan route:cache
$STD php artisan event:cache
mkdir /opt/bar-assistant/storage/bar-assistant/uploads/temp
chown -R www-data:www-data /opt/bar-assistant
msg_ok "Installed Bar Assistant"

msg_info "Installing Salt Rim"
cd /opt/vue-salt-rim
cat <<EOF >/opt/vue-salt-rim/public/config.js
window.srConfig = {}
window.srConfig.API_URL = "http://${LOCAL_IP}/bar"
window.srConfig.MEILISEARCH_URL = "http://${LOCAL_IP}/search"
EOF
$STD npm install
$STD npm run build
msg_ok "Installed Salt Rim"

msg_info "Creating Service"
cat <<EOF >/etc/nginx/sites-available/barassistant.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    client_max_body_size 100M;

    location /bar/ {
        proxy_pass http://127.0.0.1:8080/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /search/ {
        proxy_pass http://127.0.0.1:7700/;
    }

    location / {
        proxy_pass http://127.0.0.1:8081/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

server {
    listen 127.0.0.1:8080;
    server_name example.com;
    root /opt/bar-assistant/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ ^/index\.php(/|$) {
        fastcgi_pass unix:/var/run/php/php$PHPVER-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}

server {
    listen 127.0.0.1:8081;
    server_name _;
    root /opt/vue-salt-rim/dist;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

ln -s /etc/nginx/sites-available/barassistant.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
$STD systemctl reload nginx
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
