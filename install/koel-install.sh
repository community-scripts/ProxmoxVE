#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://koel.dev/

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
  ffmpeg \
  cron \
  locales
msg_ok "Installed Dependencies"

PG_VERSION="16" setup_postgresql
PG_DB_NAME="koel" PG_DB_USER="koel" setup_postgresql_db
PHP_VERSION="8.4" PHP_FPM="YES" setup_php
NODE_VERSION="22" NODE_MODULE="pnpm" setup_nodejs
setup_composer

fetch_and_deploy_gh_release "koel" "koel/koel" "prebuild" "latest" "/opt/koel" "koel-*.tar.gz"

msg_info "Configuring Koel"
mkdir -p /opt/koel_media /opt/koel_sync
cd /opt/koel
cat <<EOF >/opt/koel/.env
APP_NAME=Koel
APP_ENV=production
APP_DEBUG=false
APP_URL=http://${LOCAL_IP}
APP_KEY=

TRUSTED_HOSTS=

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=${PG_DB_NAME}
DB_USERNAME=${PG_DB_USER}
DB_PASSWORD=${PG_DB_PASS}

STORAGE_DRIVER=local
MEDIA_PATH=/opt/koel_media
ARTIFACTS_PATH=

IGNORE_DOT_FILES=true
APP_MAX_SCAN_TIME=600
MEMORY_LIMIT=

STREAMING_METHOD=php
SCOUT_DRIVER=tntsearch

USE_MUSICBRAINZ=true
MUSICBRAINZ_USER_AGENT=

LASTFM_API_KEY=
LASTFM_API_SECRET=

SPOTIFY_CLIENT_ID=
SPOTIFY_CLIENT_SECRET=

YOUTUBE_API_KEY=

CDN_URL=

TRANSCODE_FLAC=false
FFMPEG_PATH=/usr/bin/ffmpeg
TRANSCODE_BIT_RATE=128

ALLOW_DOWNLOAD=true
BACKUP_ON_DELETE=true

MEDIA_BROWSER_ENABLED=false

PROXY_AUTH_ENABLED=false

SYNC_LOG_LEVEL=error
FORCE_HTTPS=

MAIL_FROM_ADDRESS="noreply@localhost"
MAIL_FROM_NAME="Koel"
MAIL_MAILER=log
MAIL_HOST=null
MAIL_PORT=null
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null

BROADCAST_CONNECTION=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
EOF

mkdir -p /opt/koel/storage/{app/public,framework/{cache/data,sessions,views},logs}
chown -R www-data:www-data /opt/koel /opt/koel_media /opt/koel_sync
chmod -R 775 /opt/koel/storage /opt/koel/bootstrap/cache
msg_ok "Configured Koel"

msg_info "Installing Koel (Patience)"
export COMPOSER_ALLOW_SUPERUSER=1
cd /opt/koel
$STD composer install --no-interaction --no-dev --optimize-autoloader
$STD php artisan key:generate --force
$STD php artisan config:clear
$STD php artisan cache:clear
$STD php artisan koel:init --no-assets --no-interaction
chown -R www-data:www-data /opt/koel
msg_ok "Installed Koel"

msg_info "Tuning PHP-FPM"
PHP_FPM_CONF="/etc/php/8.4/fpm/pool.d/www.conf"
sed -i 's/^pm.max_children = .*/pm.max_children = 15/' "$PHP_FPM_CONF"
sed -i 's/^pm.start_servers = .*/pm.start_servers = 4/' "$PHP_FPM_CONF"
sed -i 's/^pm.min_spare_servers = .*/pm.min_spare_servers = 2/' "$PHP_FPM_CONF"
sed -i 's/^pm.max_spare_servers = .*/pm.max_spare_servers = 8/' "$PHP_FPM_CONF"
$STD systemctl restart php8.4-fpm
msg_ok "Tuned PHP-FPM"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/koel
server {
    listen 80;
    server_name _;
    root /opt/koel/public;
    index index.php;

    client_max_body_size 50M;
    charset utf-8;

    gzip on;
    gzip_types text/plain text/css application/x-javascript text/xml application/xml application/xml+rss text/javascript application/json;
    gzip_comp_level 9;

    send_timeout 3600;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location /media/ {
        internal;
        alias $upstream_http_x_media_root;
    }

    location ~ \.php$ {
        try_files $uri $uri/ /index.php?$args;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
        fastcgi_index index.php;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_intercept_errors on;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param PATH_TRANSLATED $document_root$fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/koel /etc/nginx/sites-enabled/koel
$STD systemctl reload nginx
msg_ok "Configured Nginx"

msg_info "Setting up Cron Job"
cat <<'EOF' >/etc/cron.d/koel
0 * * * * www-data cd /opt/koel && /usr/bin/php artisan koel:scan >/dev/null 2>&1
EOF
chmod 644 /etc/cron.d/koel
msg_ok "Set up Cron Job"

motd_ssh
customize
cleanup_lxc
