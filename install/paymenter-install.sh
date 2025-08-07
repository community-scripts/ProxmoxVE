#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.paymenter.org

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git \
  nginx \
  redis-server
msg_ok "Installed Dependencies"

setup_mariadb
PHP_VERSION="8.3" PHP_FPM="YES" PHP_MODULE="common,mysql,fpm,redis" setup_php
setup_composer
fetch_and_deploy_gh_release "paymenter" "paymenter/paymenter" "prebuild" "latest" "/opt/paymenter" "paymenter.tar.gz"
chmod -R 755 /opt/paymenter/storage/* /opt/paymenter/bootstrap/cache/

msg_info "Setting up database"
DB_NAME=paymenter
DB_USER=paymenter
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql mysql
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' WITH GRANT OPTION;"
{
  echo "Paymenter Database Credentials"
  echo "Database: $DB_NAME"
  echo "Username: $DB_USER"
  echo "Password: $DB_PASS"
} >>~/paymenter_db.creds
cd /opt/paymenter
cp .env.example .env
$STD composer install --no-dev --optimize-autoloader --no-interaction
$STD php artisan key:generate --force
$STD php artisan storage:link
sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/" .env
sed -i "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USER}/" .env
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASS}/" .env
$STD php artisan migrate --force --seed
msg_ok "Set up database"

msg_info "Creating Admin User"
$STD php artisan app:user:create paymenter admin admin@paymenter.org paymenter 1 -q
msg_ok "Created Admin User"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/paymenter.conf
server {
    listen 80;
    listen [::]:80;
    server_name localhost;
    root /opt/paymenter/public;

    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
ln -s /etc/nginx/sites-available/paymenter.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
$STD systemctl reload nginx
chown -R www-data:www-data /opt/paymenter/*
msg_ok "Configured Nginx"

msg_info "Setting up Cronjob"
echo "* * * * * php /opt/paymenter/artisan schedule:run >> /dev/null 2>&1" | crontab -
msg_ok "Setup Cronjob"

msg_info "Setting up Service"
cat <<EOF >/etc/systemd/system/paymenter.service
[Unit]
Description=Paymenter Queue Worker

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /opt/paymenter/artisan queue:work
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now paymenter
systemctl enable --now redis-server
msg_ok "Setup Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

