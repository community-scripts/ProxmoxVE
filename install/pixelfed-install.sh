#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pixelfed.org/

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
  redis-server \
  ffmpeg \
  jpegoptim \
  optipng \
  pngquant \
  gifsicle \
  libvips42
msg_ok "Installed Dependencies"

msg_info "Creating Pixelfed User"
useradd -rU -s /bin/bash pixelfed
usermod -aG redis pixelfed
msg_ok "Created Pixelfed User"


PG_VERSION="17" setup_postgresql
PG_DB_NAME="pixelfed" PG_DB_USER="pixelfed" setup_postgresql_db
PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="bcmath,ctype,curl,exif,gd,imagick,intl,mbstring,pgsql,redis,xml,zip" PHP_UPLOAD_MAX_FILESIZE="500M" PHP_POST_MAX_SIZE="500M" PHP_MAX_EXECUTION_TIME="600" setup_php
setup_composer

msg_info "Configuring Redis"
REDIS_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
sed -i "s/^# requirepass foobared/requirepass $REDIS_PASS/" /etc/redis/redis.conf
sed -i "s/^requirepass .*/requirepass $REDIS_PASS/" /etc/redis/redis.conf
systemctl restart redis-server
msg_ok "Configured Redis"

msg_info "Configuring PHP-FPM Pool"
cp /etc/php/8.4/fpm/pool.d/www.conf /etc/php/8.4/fpm/pool.d/pixelfed.conf
sed -i 's/\[www\]/[pixelfed]/' /etc/php/8.4/fpm/pool.d/pixelfed.conf
sed -i 's/^user = www-data/user = pixelfed/' /etc/php/8.4/fpm/pool.d/pixelfed.conf
sed -i 's/^group = www-data/group = pixelfed/' /etc/php/8.4/fpm/pool.d/pixelfed.conf
sed -i 's|^listen = .*|listen = /run/php/php8.4-fpm-pixelfed.sock|' /etc/php/8.4/fpm/pool.d/pixelfed.conf
sed -i 's/^listen.owner = .*/listen.owner = www-data/' /etc/php/8.4/fpm/pool.d/pixelfed.conf
sed -i 's/^listen.group = .*/listen.group = www-data/' /etc/php/8.4/fpm/pool.d/pixelfed.conf
systemctl restart php8.4-fpm
msg_ok "Configured PHP-FPM Pool"

fetch_and_deploy_gh_release "pixelfed" "pixelfed/pixelfed" "tarball" "latest" "/opt/pixelfed"

msg_info "Installing Pixelfed (Patience)"
cd /opt/pixelfed
cat <<EOF >/opt/pixelfed/.env
APP_NAME="Pixelfed"
APP_ENV="production"
APP_KEY=
APP_DEBUG="false"
APP_URL=http://${LOCAL_IP}
APP_DOMAIN=${LOCAL_IP}
ADMIN_DOMAIN=${LOCAL_IP}
SESSION_DOMAIN=${LOCAL_IP}
TRUST_PROXIES="*"
FORCE_HTTPS_URLS="false"

OPEN_REGISTRATION="false"
ENFORCE_EMAIL_VERIFICATION="false"
PF_MAX_USERS="1000"
OAUTH_ENABLED="true"
ENABLE_CONFIG_CACHE="true"
INSTANCE_DISCOVER_PUBLIC="true"

PF_OPTIMIZE_IMAGES="true"
IMAGE_QUALITY="80"
MAX_PHOTO_SIZE="15000"
MAX_CAPTION_LENGTH="500"
MAX_ALBUM_LENGTH="4"

DB_CONNECTION="pgsql"
DB_HOST="127.0.0.1"
DB_PORT="5432"
DB_DATABASE="${PG_DB_NAME}"
DB_USERNAME="${PG_DB_USER}"
DB_PASSWORD="${PG_DB_PASS}"

REDIS_CLIENT="predis"
REDIS_SCHEME="tcp"
REDIS_HOST="127.0.0.1"
REDIS_PASSWORD="${REDIS_PASS}"
REDIS_PORT="6379"

SESSION_DRIVER="database"
CACHE_DRIVER="redis"
QUEUE_DRIVER="redis"
BROADCAST_DRIVER="log"
LOG_CHANNEL="stack"
HORIZON_PREFIX="horizon-"

ACTIVITY_PUB="true"
AP_REMOTE_FOLLOW="true"
AP_INBOX="true"
AP_OUTBOX="true"
AP_SHAREDINBOX="true"

EXP_EMC="true"

MAIL_DRIVER="log"
MAIL_HOST="smtp.mailtrap.io"
MAIL_PORT="2525"
MAIL_USERNAME="null"
MAIL_PASSWORD="null"
MAIL_ENCRYPTION="null"
MAIL_FROM_ADDRESS="pixelfed@example.com"
MAIL_FROM_NAME="Pixelfed"

PF_ENABLE_CLOUD="false"
FILESYSTEM_CLOUD="s3"
SESSION_SECURE_COOKIE="false"
HTTPS="false"
EOF
chmod -R 755 /opt/pixelfed
chmod -R 775 /opt/pixelfed/storage /opt/pixelfed/bootstrap/cache
export COMPOSER_ALLOW_SUPERUSER=1
$STD composer install --no-dev --no-ansi --no-interaction --optimize-autoloader
$STD php artisan key:generate --force
$STD php artisan storage:link
$STD php artisan migrate --force
$STD php artisan import:cities
$STD php artisan passport:keys
$STD php artisan route:cache
$STD php artisan view:cache
$STD php artisan config:cache
$STD php artisan instance:actor
$STD php artisan horizon:install
chown -R pixelfed:pixelfed /opt/pixelfed
msg_ok "Installed Pixelfed"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/pixelfed
server {
    listen 80;
    server_name _;
    root /opt/pixelfed/public;
    index index.php;

    charset utf-8;
    client_max_body_size 100M;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.4-fpm-pixelfed.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
ln -sf /etc/nginx/sites-available/pixelfed /etc/nginx/sites-enabled/pixelfed
rm -f /etc/nginx/sites-enabled/default
$STD nginx -t
systemctl reload nginx
msg_ok "Configured Nginx"

msg_info "Creating Services"
cat <<'EOF' >/etc/systemd/system/pixelfed-horizon.service
[Unit]
Description=Pixelfed Horizon Queue Worker
After=network.target redis-server.service postgresql.service
Requires=redis-server.service

[Service]
Type=simple
User=pixelfed
WorkingDirectory=/opt/pixelfed
ExecStart=/usr/bin/php /opt/pixelfed/artisan horizon
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<'EOF' >/etc/systemd/system/pixelfed-scheduler.service
[Unit]
Description=Pixelfed Task Scheduler
After=network.target

[Service]
Type=oneshot
User=pixelfed
WorkingDirectory=/opt/pixelfed
ExecStart=/usr/bin/php /opt/pixelfed/artisan schedule:run
EOF

cat <<'EOF' >/etc/systemd/system/pixelfed-scheduler.timer
[Unit]
Description=Run Pixelfed Scheduler every minute

[Timer]
OnCalendar=*-*-* *:*:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl enable -q --now pixelfed-horizon pixelfed-scheduler.timer
msg_ok "Created Services"


motd_ssh
customize
cleanup_lxc
