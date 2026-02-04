#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Benito Rodríguez (b3ni)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/investbrainapp/investbrain

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
  supervisor \
  redis-server \
  libfreetype-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  zlib1g-dev \
  libzip-dev \
  libicu-dev \
  libpq-dev
msg_ok "Installed Dependencies"

export PHP_VERSION="8.4"
PHP_FPM="YES" PHP_MODULE="pdo-pgsql" setup_php
setup_composer
NODE_VERSION="22" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_NAME="investbrain" PG_DB_USER="investbrain" setup_postgresql_db

fetch_and_deploy_gh_release "Investbrain" "investbrainapp/investbrain" "tarball" "latest" "/opt/investbrain"

msg_info "Installing Investbrain"
APP_KEY=$(openssl rand -base64 32)
cd /opt/investbrain
cat <<EOF >/opt/investbrain/.env
APP_KEY=base64:${APP_KEY}
APP_PORT=8000
APP_URL=http://${LOCAL_IP}:8000
ASSET_URL=http://${LOCAL_IP}:8000

LOG_CHANNEL=daily
LOG_LEVEL=warning

REGISTRATION_ENABLED=true

AI_CHAT_ENABLED=false
OPENAI_API_KEY=
OPENAI_ORGANIZATION=

MARKET_DATA_PROVIDER=yahoo
ALPHAVANTAGE_API_KEY=
FINNHUB_API_KEY=
ALPACA_API_KEY=
ALPACA_API_SECRET=
TWELVEDATA_API_SECRET=

MARKET_DATA_REFRESH=30
DAILY_CHANGE_TIME=

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=${PG_DB_NAME}
DB_USERNAME=${PG_DB_USER}
DB_PASSWORD=${PG_DB_PASS}

REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

CACHE_STORE=redis
CACHE_PREFIX=

SESSION_DRIVER=redis
SESSION_LIFETIME=120

QUEUE_CONNECTION=redis

MAIL_MAILER=log
MAIL_HOST=127.0.0.1
MAIL_PORT=2525
MAIL_FROM_ADDRESS="investbrain@${LOCAL_IP}"

VITE_APP_NAME=Investbrain
EOF
export COMPOSER_ALLOW_SUPERUSER=1
$STD /usr/local/bin/composer install --no-interaction --no-dev --optimize-autoloader
$STD npm install
$STD npm run build
mkdir -p /opt/investbrain/storage/{framework/cache,framework/sessions,framework/views,app,logs}
$STD php artisan migrate --force
$STD php artisan storage:link
$STD php artisan cache:clear
$STD php artisan view:clear
$STD php artisan route:clear
$STD php artisan event:clear
$STD php artisan route:cache
$STD php artisan event:cache
chown -R www-data:www-data /opt/investbrain
chmod -R 775 /opt/investbrain/bootstrap/cache
msg_ok "Installed Investbrain"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/investbrain.conf
server {
    listen 8000 default_server;
    listen [::]:8000 default_server;
    server_name _;

    root /opt/investbrain/public;
    index index.php;

    client_max_body_size 50M;
    charset utf-8;

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    error_log /var/log/nginx/investbrain_error.log;
    access_log /var/log/nginx/investbrain_access.log;
}
EOF
ln -sf /etc/nginx/sites-available/investbrain.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
$STD systemctl reload nginx
msg_ok "Configured Nginx"

msg_info "Setting up Supervisor"
cat <<EOF >/etc/supervisor/conf.d/investbrain.conf
[program:investbrain-queue]
process_name=%%(program_name)s_%%(process_num)02d
command=php /opt/investbrain/artisan queue:work --sleep=3 --tries=1 --memory=256 --timeout=3600
user=www-data
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/opt/investbrain/storage/logs/queue.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=10
numprocs=1
EOF
$STD supervisorctl reread
$STD supervisorctl update
$STD supervisorctl start all
msg_ok "Setup Supervisor"

msg_info "Setting up Cron for Scheduler"
cat <<EOF >/etc/cron.d/investbrain-scheduler
* * * * * www-data php /opt/investbrain/artisan schedule:run >> /dev/null 2>&1
EOF
chmod 644 /etc/cron.d/investbrain-scheduler
$STD systemctl restart cron
msg_ok "Setup Cron for Scheduler"

motd_ssh
customize
cleanup_lxc
