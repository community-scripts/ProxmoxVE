#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: AlphaLawless
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/alexjustesen/speedtest-tracker

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
  sqlite3
setcap cap_net_raw+ep /bin/ping
msg_ok "Installed Dependencies"

PHP_VERSION="8.4" PHP_FPM="YES" setup_php
setup_composer
NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "speedtest-tracker" "alexjustesen/speedtest-tracker" "tarball"

msg_info "Installing Speedtest CLI"
setup_deb822_repo \
  "speedtest-cli" \
  "https://packagecloud.io/ookla/speedtest-cli/gpgkey" \
  "https://packagecloud.io/ookla/speedtest-cli/debian" \
  "$(get_os_info codename)" \
  "main"
$STD apt install -y speedtest
msg_ok "Installed Speedtest CLI"

msg_info "Configuring PHP-FPM runtime directory"
mkdir -p /etc/systemd/system/php8.4-fpm.service.d/
cat <<EOF >/etc/systemd/system/php8.4-fpm.service.d/override.conf
[Service]
RuntimeDirectory=php
RuntimeDirectoryMode=0755
EOF
msg_ok "Configured PHP-FPM runtime directory"

msg_info "Setting up Speedtest Tracker"
cd /opt/speedtest-tracker
APP_KEY=$(php -r "echo bin2hex(random_bytes(16));")
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
cat <<EOF >/opt/speedtest-tracker/.env
APP_NAME="Speedtest Tracker"
APP_ENV=production
APP_TIMEZONE=${TIMEZONE}
APP_KEY=base64:$(echo -n $APP_KEY | base64)
APP_DEBUG=false
APP_URL=http://${LOCAL_IP}

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=sqlite
DB_DATABASE=/opt/speedtest-tracker/database/database.sqlite

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

SPEEDTEST_SCHEDULE="0 */6 * * *"
SPEEDTEST_SERVERS=
SPEEDTEST_EXTERNAL_IP_URL=https://ip.me 
SPEEDTEST_INTERNET_CHECK_HOSTNAME=1.1.1.1
PRUNE_RESULTS_OLDER_THAN=0

DISPLAY_TIMEZONE=${TIMEZONE}
EOF
mkdir -p /opt/speedtest-tracker/database
touch /opt/speedtest-tracker/database/database.sqlite
export COMPOSER_ALLOW_SUPERUSER=1
$STD composer install --optimize-autoloader --no-dev
$STD npm ci
$STD npm run build
$STD php artisan key:generate --force
$STD php artisan migrate --force --seed
$STD php artisan config:clear
$STD php artisan cache:clear
$STD php artisan view:clear
chown -R www-data:www-data /opt/speedtest-tracker
chmod -R 755 /opt/speedtest-tracker/storage
chmod -R 755 /opt/speedtest-tracker/bootstrap/cache
msg_ok "Set up Speedtest Tracker"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/speedtest-tracker.service
[Unit]
Description=Speedtest Tracker Queue Worker
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /opt/speedtest-tracker/artisan queue:work --sleep=3 --tries=3 --max-time=3600
WorkingDirectory=/opt/speedtest-tracker

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now speedtest-tracker
msg_ok "Created Service"

msg_info "Setting up Scheduler"
cat <<EOF >/etc/cron.d/speedtest-tracker
* * * * * www-data cd /opt/speedtest-tracker && php artisan schedule:run >> /dev/null 2>&1
EOF
msg_ok "Set up Scheduler"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/speedtest-tracker
server {
    listen 80;
    server_name _;
    root /opt/speedtest-tracker/public;

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

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/speedtest-tracker /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
