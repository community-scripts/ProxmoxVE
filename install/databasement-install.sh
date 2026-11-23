#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/David-Crty/databasement

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
  git \
  mariadb-client \
  redis-tools \
  sqlite3 \
  sshpass \
  zstd \
  7zip
msg_ok "Installed Dependencies"

msg_info "Installing PostgreSQL Clients"
setup_deb822_repo \
  "pgdg" \
  "https://www.postgresql.org/media/keys/ACCC4CF8.asc" \
  "https://apt.postgresql.org/pub/repos/apt" \
  "$(get_os_info codename)-pgdg" \
  "main"
# pg_dump on PATH resolves to the newest client; Databasement switches to the 16 client for servers up to 16
$STD apt install -y \
  postgresql-client-16 \
  postgresql-client-18
msg_ok "Installed PostgreSQL Clients"

# MongoDB ships no Debian 13 build of its tools and only an amd64 Debian 12 one; the Ubuntu 24.04 build covers both
fetch_and_deploy_from_url "https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2404-$(arch_resolve "x86_64" "arm64")-$(get_latest_gh_tag "mongodb/mongo-tools" "100.").deb"

PHP_VERSION="8.5" PHP_FPM="YES" PHP_MODULE="mongodb,smbclient" setup_php
setup_composer
NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "databasement" "David-Crty/databasement" "tarball"

msg_info "Setting up Databasement"
mkdir -p /opt/databasement_data/backups
touch /opt/databasement_data/database.sqlite
cat <<EOF >/opt/databasement_data/.env
APP_NAME=Databasement
APP_ENV=production
APP_KEY=base64:$(openssl rand -base64 32)
APP_DEBUG=false
APP_URL=http://${LOCAL_IP}
APP_VERSION=$(cat ~/.databasement)
APP_DISPLAY_TIMEZONE=UTC

DB_CONNECTION=sqlite
DB_DATABASE=/opt/databasement_data/database.sqlite

LOG_LEVEL=warning
EOF
ln -sf /opt/databasement_data/.env /opt/databasement/.env
# the demo backup offered at sign-up writes to /data/backups, the volume path of the upstream image
ln -s /opt/databasement_data /data
cd /opt/databasement
$STD composer install --no-dev --optimize-autoloader --no-interaction
$STD php artisan vendor:publish --force --tag=livewire:assets
$STD npm ci --ignore-scripts
$STD npm run build
$STD php artisan migrate --force
$STD php artisan optimize
chown -R www-data:www-data /opt/databasement /opt/databasement_data
chmod 600 /opt/databasement_data/.env
msg_ok "Set up Databasement"

msg_info "Configuring Nginx"
PHP_SOCK=$(get_php_fpm_socket)
cat <<EOF >/etc/nginx/sites-available/databasement
server {
    listen 80;
    server_name _;
    root /opt/databasement/public;

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

    location ~ \.php\$ {
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
nginx_enable_site "databasement"
msg_ok "Configured Nginx"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/databasement-worker.service
[Unit]
Description=Databasement Queue Worker
After=network.target php8.5-fpm.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/databasement
ExecStart=/usr/bin/php artisan queue:work --queue=backups,default --tries=3 --timeout=3600 --sleep=3 --max-jobs=1000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/databasement-scheduler.service
[Unit]
Description=Databasement Scheduler
After=network.target php8.5-fpm.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/databasement
ExecStart=/usr/bin/php artisan schedule:work --quiet
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now databasement-worker databasement-scheduler
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
