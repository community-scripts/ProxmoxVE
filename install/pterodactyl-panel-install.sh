#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pterodactyl/panel

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  lsb-release \
  redis \
  apache2 \
  composer
msg_ok "Installed Dependencies"

setup_mariadb

msg_info "Adding PHP8.4 Repository"
$STD curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
$STD dpkg -i /tmp/debsuryorg-archive-keyring.deb
$STD sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
$STD apt-get update
msg_ok "Added PHP8.4 Repository"

msg_info "Installing PHP"
$STD apt-get remove -y php8.2*
$STD apt-get install -y \
  php8.4 \
  php8.4-{gd,mysql,mbstring,bcmath,xml,curl,zip,intl,fpm} \
  libapache2-mod-php8.4
msg_ok "Installed PHP"

msg_info "Setting up MariaDB"
DB_NAME=panel
DB_USER=pterodactyl
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "pterodactyl Panel-Credentials"
  echo "pterodactyl Panel Database User: $DB_USER"
  echo "pterodactyl Panel Database Password: $DB_PASS"
  echo "pterodactyl Panel Database Name: $DB_NAME"
} >>~/pterodactyl-panel.creds
msg_ok "Set up MariaDB"

read -p "${TAB3}Provide an email address for admin login, this should be a valid email address: " ADMIN_EMAIL
read -p "${TAB3}Enter your First Name: " NAME_FIRST
read -p "${TAB3}Enter your Last Name: " NAME_LAST

msg_info "Installing pterodactyl Panel"
RELEASE=$(curl -fsSL https://api.github.com/repos/pterodactyl/panel/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
mkdir /opt/pterodactyl-panel
cd /opt/pterodactyl-panel
curl -fsSL "https://github.com/pterodactyl/panel/releases/download/v${RELEASE}/panel.tar.gz" -o "panel.tar.gz"
tar -xzf "panel.tar.gz"
cp .env.example .env
IP=$(hostname -I | awk '{print $1}')
ADMIN_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD composer install --no-dev --optimize-autoloader --no-interaction
$STD php artisan key:generate --force
$STD php artisan p:environment:setup --no-interaction --author "$ADMIN_EMAIL" --url "http://$IP"
$STD php artisan p:environment:database --no-interaction --database $DB_NAME --username $DB_USER --password "$DB_PASS"
$STD php artisan migrate --seed --force --no-interaction
$STD php artisan p:user:make --no-interaction --admin=1 --email "$ADMIN_EMAIL" --password "$ADMIN_PASS" --name-first "$NAME_FIRST" --name-last "$NAME_LAST" --username "admin"
echo "* * * * * php /opt/pterodactyl-panel/artisan schedule:run >> /dev/null 2>&1" | crontab -u www-data -
chown -R www-data:www-data /opt/pterodactyl-panel/*
chmod -R 755 /opt/pterodactyl-panel/storage/* /opt/pterodactyl-panel/bootstrap/cache/
{
  echo ""
  echo "pterodactyl Admin Username: admin"
  echo "pterodactyl Admin Email: $ADMIN_EMAIL"
  echo "pterodactyl Admin Password: $ADMIN_PASS"
} >>~/pterodactyl-panel.creds

echo "${RELEASE}" >/opt/"${APPLICATION}"_version.txt
msg_ok "Installed pterodactyl Panel"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/pteroq.service
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /opt/pterodactyl-panel/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pteroq
cat <<EOF >/etc/apache2/sites-available/pterodactyl.conf
<VirtualHost *:80>
    ServerName pterodactyl
    DocumentRoot /opt/pterodactyl-panel/public

    AllowEncodedSlashes On
    
    php_value upload_max_filesize 100M
    php_value post_max_size 100M

    <Directory /opt/pterodactyl-panel/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/pterodactyl_error.log
    CustomLog /var/log/apache2/pterodactyl_access.log combined
</VirtualHost>
EOF
$STD a2ensite pterodactyl
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "/opt/pterodactyl-panel/panel.tar.gz"
rm -rf "/tmp/debsuryorg-archive-keyring.deb"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
