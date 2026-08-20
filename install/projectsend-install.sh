#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.projectsend.org/ | Github: https://github.com/projectsend/projectsend

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="ldap,pcntl" setup_php
setup_mariadb
MARIADB_DB_NAME="projectsend"
MARIADB_DB_USER="projectsend"
setup_mariadb_db
fetch_and_deploy_gh_release "projectsend" "projectsend/projectsend" "prebuild" "latest" "/opt/projectsend" "projectsend-*.zip"

msg_info "Configuring ProjectSend"
cd /opt/projectsend
cp .env.example .env
ADMIN_EMAIL="admin@example.com"
ADMIN_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
sed -i \
  -e "s|^APP_ENV=.*|APP_ENV=production|" \
  -e "s|^APP_DEBUG=.*|APP_DEBUG=false|" \
  -e "s|^APP_URL=.*|APP_URL=http://${LOCAL_IP}|" \
  -e "s|^DB_HOST=.*|DB_HOST=localhost|" \
  -e "s|^DB_DATABASE=.*|DB_DATABASE=${MARIADB_DB_NAME}|" \
  -e "s|^DB_USERNAME=.*|DB_USERNAME=${MARIADB_DB_USER}|" \
  -e "s|^DB_PASSWORD=.*|DB_PASSWORD=${MARIADB_DB_PASS}|" \
  -e "s|^SESSION_DRIVER=.*|SESSION_DRIVER=database|" \
  -e "s|^CACHE_STORE=.*|CACHE_STORE=database|" \
  -e "s|^QUEUE_CONNECTION=.*|QUEUE_CONNECTION=database|" \
  .env
chown -R www-data:www-data /opt/projectsend
chmod -R 775 /opt/projectsend/storage /opt/projectsend/bootstrap/cache
$STD sudo -u www-data php artisan key:generate --force --no-interaction
$STD sudo -u www-data php artisan migrate --force
$STD sudo -u www-data php artisan storage:link --force
$STD sudo -u www-data php artisan projectsend:ensure-roles
$STD sudo -u www-data php artisan projectsend:admin --if-none \
  --name="Administrator" \
  --email="${ADMIN_EMAIL}" \
  --password="${ADMIN_PASSWORD}"
cat <<EOF >~/projectsend.creds
ProjectSend Credentials
Admin Email: ${ADMIN_EMAIL}
Admin Password: ${ADMIN_PASSWORD}
EOF
msg_ok "Configured ProjectSend"

msg_info "Creating Service"
PHP_SOCK=$(get_php_fpm_socket)
cat <<EOF >/etc/nginx/sites-available/projectsend.conf
server {
    listen 80 default_server;
    server_name _;
    root /opt/projectsend/public;
    index index.php;

    client_max_body_size 100m;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location /protected-files/ {
        internal;
        alias /opt/projectsend/storage/app/files/;
    }

    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_buffer_size 32k;
        fastcgi_buffers 8 32k;
    }

    location ~ /\.(?!well-known) {
        deny all;
    }
}
EOF
nginx_enable_site projectsend.conf

cat <<EOF >/etc/systemd/system/projectsend-worker.service
[Unit]
Description=ProjectSend queue worker
After=network.target mariadb.service

[Service]
User=www-data
Group=www-data
Restart=always
WorkingDirectory=/opt/projectsend
ExecStart=/usr/bin/php artisan queue:work --tries=3 --backoff=3

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now projectsend-worker

echo "* * * * * cd /opt/projectsend && php artisan schedule:run >> /dev/null 2>&1" | crontab -u www-data -
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
