#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://invoiceninja.com/

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
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2
msg_ok "Installed Dependencies"

setup_mariadb
MARIADB_DB_NAME="invoiceninja" MARIADB_DB_USER="invoiceninja" setup_mariadb_db
PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="soap" setup_php

fetch_and_deploy_gh_release "invoiceninja" "invoiceninja/invoiceninja" "prebuild" "latest" "/opt/invoiceninja" "invoiceninja.tar.gz"

msg_info "Configuring InvoiceNinja"
cd /opt/invoiceninja
APP_KEY=$(php artisan key:generate --show)
cat <<EOF >/opt/invoiceninja/.env
APP_NAME="Invoice Ninja"
APP_ENV=production
APP_KEY=${APP_KEY}
APP_DEBUG=false
APP_URL=http://${LOCAL_IP}:8080

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=${MARIADB_DB_NAME}
DB_USERNAME=${MARIADB_DB_USER}
DB_PASSWORD=${MARIADB_DB_PASS}

MULTI_DB_ENABLED=false
DEMO_MODE=false

BROADCAST_DRIVER=log
LOG_CHANNEL=stack
CACHE_DRIVER=file
QUEUE_CONNECTION=database
SESSION_DRIVER=file
SESSION_LIFETIME=120

MAIL_MAILER=log
MAIL_HOST=null
MAIL_PORT=null
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="noreply@localhost"
MAIL_FROM_NAME="Invoice Ninja"

REQUIRE_HTTPS=false
NINJA_ENVIRONMENT=selfhost
PDF_GENERATOR=snappdf

TRUSTED_PROXIES=*
INTERNAL_QUEUE_ENABLED=false
EOF

mkdir -p /opt/invoiceninja/bootstrap/cache
mkdir -p /opt/invoiceninja/storage/{app/public,framework/{cache/data,sessions,views},logs}
chown -R www-data:www-data /opt/invoiceninja
chown -R www-data:www-data /opt/invoiceninja/storage
chown -R www-data:www-data /opt/invoiceninja/bootstrap/cache
msg_ok "Configured InvoiceNinja"

msg_info "Downloading Chromium for PDF Generation"
cd /opt/invoiceninja
$STD ./vendor/bin/snappdf download
chown -R www-data:www-data /opt/invoiceninja/vendor/beganovich/snappdf/versions
msg_ok "Downloaded Chromium for PDF Generation"

msg_info "Setting up Database"
cd /opt/invoiceninja
$STD php artisan config:clear
$STD php artisan cache:clear
$STD php artisan route:clear
$STD php artisan view:clear
$STD php artisan migrate --force
$STD php artisan db:seed --force
$STD php artisan ninja:post-update
$STD php artisan optimize
chown -R www-data:www-data /opt/invoiceninja
msg_ok "Set up Database"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/invoiceninja
server {
    listen 8080;
    server_name _;
    root /opt/invoiceninja/public;
    index index.php;

    client_max_body_size 50M;
    charset utf-8;

    gzip on;
    gzip_types application/javascript application/x-javascript text/javascript text/plain application/xml application/json;
    gzip_proxied no-cache no-store private expired auth;
    gzip_min_length 1000;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /index.php {
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    location ~ \.php$ {
        return 403;
    }

    location ~ /\.ht {
        deny all;
    }

    error_log /var/log/nginx/invoiceninja_error.log;
    access_log /var/log/nginx/invoiceninja_access.log;
}
EOF

ln -sf /etc/nginx/sites-available/invoiceninja /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
$STD systemctl reload nginx
msg_ok "Configured Nginx"

msg_info "Setting up Queue Worker"
cat <<'EOF' >/etc/supervisor/conf.d/invoiceninja-worker.conf
[program:invoiceninja-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /opt/invoiceninja/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/log/invoiceninja-worker.log
stopwaitsecs=3600
EOF

touch /var/log/invoiceninja-worker.log
chown www-data:www-data /var/log/invoiceninja-worker.log
$STD supervisorctl reread
$STD supervisorctl update
msg_ok "Set up Queue Worker"

msg_info "Setting up Cron"
cat <<'EOF' >/etc/cron.d/invoiceninja
* * * * * www-data cd /opt/invoiceninja && php artisan schedule:run >> /dev/null 2>&1
EOF
msg_ok "Set up Cron"

msg_info "Enabling Services"
systemctl enable -q --now php8.4-fpm nginx supervisor
msg_ok "Enabled Services"

motd_ssh
customize
cleanup_lxc
