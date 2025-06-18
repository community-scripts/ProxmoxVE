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
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  nginx \
  redis-server
msg_ok "Installed Dependencies"

setup_mariadb

msg_info "Adding PHP Repository"
$STD curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
$STD dpkg -i /tmp/debsuryorg-archive-keyring.deb
$STD sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
$STD apt-get update
msg_ok "Added PHP Repository"

msg_info "Installing PHP"
$STD apt-get remove -y php8.2*
$STD apt-get install -y \
  php8.3 \
  php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,curl,zip,intl,fpm,redis}
msg_info "Installed PHP"

msg_info "Installing Composer"
$STD curl -fsSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
msg_ok "Installed Composer"

msg_info "Installing Paymenter"
RELEASE=$(curl -fsSL https://api.github.com/repos/paymenter/paymenter/releases/latest | grep '"tag_name"' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
echo "${RELEASE}" >/opt/"${APPLICATION}"_version.txt
mkdir -p /opt/paymenter
cd /opt/paymenter
curl -fsSL "https://github.com/paymenter/paymenter/releases/download/${RELEASE}/paymenter.tar.gz" -o paymenter.tar.gz
$STD tar -xzvf paymenter.tar.gz
chmod -R 755 storage/* bootstrap/cache/
msg_ok "Installed Paymenter"

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

msg_info "Cleaning up"
rm -rf /opt/paymenter/paymenter.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
