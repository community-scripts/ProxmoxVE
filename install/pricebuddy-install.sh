#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/jez500/pricebuddy

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
  cron \
  xvfb
msg_ok "Installed Dependencies"

PHP_VERSION="8.4" PHP_FPM="YES" PHP_MEMORY_LIMIT="2048M" setup_php
setup_composer
NODE_VERSION="22" setup_nodejs
setup_mariadb
MARIADB_DB_NAME="pricebuddy" MARIADB_DB_USER="pricebuddy" setup_mariadb_db
PYTHON_VERSION="3.12" setup_uv

msg_info "Installing Google Chrome"
setup_deb822_repo \
  "google-chrome" \
  "https://dl.google.com/linux/linux_signing_key.pub" \
  "https://dl.google.com/linux/chrome/deb/" \
  "stable"
$STD apt install -y google-chrome-stable
# the package adds its own .list for the same repo, which apt rejects next to the deb822 source
rm -f /etc/apt/sources.list.d/google-chrome.list
msg_ok "Installed Google Chrome"

fetch_and_deploy_gh_release "seleniumbase-scrapper" "jez500/seleniumbase-scrapper" "tarball"

msg_info "Setting up SeleniumBase Scrapper"
$STD uv venv --python 3.12 /opt/seleniumbase-scrapper/.venv
# the SeleniumBase release upstream builds and tests its image against
$STD uv pip install --python /opt/seleniumbase-scrapper/.venv/bin/python \
  "seleniumbase==$(sed -n 's/^ARG SELENIUMBASE_VERSION=v//p' /opt/seleniumbase-scrapper/Dockerfile)" \
  flask \
  beautifulsoup4
$STD /opt/seleniumbase-scrapper/.venv/bin/seleniumbase get chromedriver
msg_ok "Set up SeleniumBase Scrapper"

fetch_and_deploy_gh_release "pricebuddy" "jez500/pricebuddy" "tarball"

msg_info "Setting up PriceBuddy"
cd /opt/pricebuddy
cat <<EOF >/opt/pricebuddy/.env
APP_NAME=PriceBuddy
APP_ENV=production
APP_KEY=base64:$(openssl rand -base64 32)
APP_DEBUG=false
APP_URL=http://${LOCAL_IP}
APP_VERSION=$(cat ~/.pricebuddy)

DB_CONNECTION=mariadb
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=pricebuddy
DB_USERNAME=pricebuddy
DB_PASSWORD=${MARIADB_DB_PASS}

SCRAPER_BASE_URL=http://127.0.0.1:3000

APP_USER_EMAIL=admin@example.com
APP_USER_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c16)
EOF
$STD composer install --no-dev --optimize-autoloader --no-interaction
$STD npm install
$STD npm run build
$STD php artisan storage:link
# reads APP_USER_* for the admin via env(), so it has to run before optimize caches the config
$STD php artisan buddy:init-db
$STD php artisan optimize
$STD php artisan icons:cache
chown -R www-data:www-data /opt/pricebuddy
chmod 600 /opt/pricebuddy/.env
msg_ok "Set up PriceBuddy"

msg_info "Configuring Nginx"
PHP_SOCK=$(get_php_fpm_socket)
cat <<EOF >/etc/nginx/sites-available/pricebuddy
server {
    listen 80;
    server_name _;
    root /opt/pricebuddy/public;

    index index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php\$ {
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
nginx_enable_site "pricebuddy"
msg_ok "Configured Nginx"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/seleniumbase-scrapper.service
[Unit]
Description=SeleniumBase Scrapper for PriceBuddy
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/seleniumbase-scrapper/api
Environment=API_HOST=127.0.0.1
Environment=API_PORT=3000
ExecStart=/opt/seleniumbase-scrapper/.venv/bin/python /opt/seleniumbase-scrapper/api/server.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/pricebuddy-worker.service
[Unit]
Description=PriceBuddy Queue Worker
After=network.target mariadb.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/pricebuddy
ExecStart=/usr/bin/php /opt/pricebuddy/artisan queue:work
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/cron.d/pricebuddy
* * * * * www-data cd /opt/pricebuddy && php artisan schedule:run >/dev/null 2>&1
EOF
systemctl enable -q --now seleniumbase-scrapper pricebuddy-worker
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
