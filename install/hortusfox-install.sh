#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/danielbrendel/hortusfox-web

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y apache2
msg_ok "Installed Dependencies"

setup_mariadb
PHP_MODULE="exif,mysql" PHP_APACHE="YES" PHP_FPM="NO" PHP_VERSION="8.3" setup_php
setup_composer

msg_info "Setting up database"
DB_NAME=hortusfox
DB_USER=hortusfox
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "HortusFox Database Credentials"
  echo "Database: $DB_NAME"
  echo "Username: $DB_USER"
  echo "Password: $DB_PASS"
} >>~/hortusfox.creds
msg_ok "Set up database"

fetch_and_deploy_gh_release "hortusfox" "danielbrendel/hortusfox-web"

msg_info "Configuring .env"
cp /opt/hortusfox/.env.example /opt/hortusfox/.env
sed -i "s|^DB_HOST=.*|DB_HOST=localhost|" /opt/hortusfox/.env
sed -i "s|^DB_USER=.*|DB_USER=$DB_USER|" /opt/hortusfox/.env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|" /opt/hortusfox/.env
sed -i "s|^DB_DATABASE=.*|DB_DATABASE=$DB_NAME|" /opt/hortusfox/.env
sed -i "s|^DB_ENABLE=.*|DB_ENABLE=true|" /opt/hortusfox/.env
sed -i "s|^APP_TIMEZONE=.*|APP_TIMEZONE=Europe/Berlin|" /opt/hortusfox/.env
msg_ok ".env configured"

msg_info "Installing Composer dependencies"
cd /opt/hortusfox
$STD composer install --no-dev --optimize-autoloader
msg_ok "Composer dependencies installed"

msg_info "Running DB migration"
$STD php asatru migrate:fresh
msg_ok "Migration finished"

msg_info "Setting up HortusFox"
$STD mariadb -u root -D $DB_NAME -e "INSERT IGNORE INTO AppModel (workspace, language, created_at) VALUES ('Default Workspace', 'en', NOW());"
$STD php asatru plants:attributes
$STD php asatru calendar:classes
ADMIN_EMAIL="admin@example.com"
ADMIN_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)"
ADMIN_HASH=$(php -r "echo password_hash('$ADMIN_PASS', PASSWORD_BCRYPT);")
$STD mariadb -u root -D $DB_NAME -e "INSERT IGNORE INTO UserModel (name, email, password, admin) VALUES ('Admin', '$ADMIN_EMAIL', '$ADMIN_HASH', 1);"
{
  echo ""
  echo "HortusFox-Admin-Creds:"
  echo "E-Mail: $ADMIN_EMAIL"
  echo "Passwort: $ADMIN_PASS"
} >>~/hortusfox.creds
$STD mariadb -u root -D $DB_NAME -e "INSERT IGNORE INTO LocationsModel (name, active, created_at) VALUES ('Home', 1, NOW());"
msg_ok "Set up HortusFox"

msg_info "Configuring Apache vHost"
cat <<EOF >/etc/apache2/sites-available/hortusfox.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /opt/hortusfox/public
    <Directory /opt/hortusfox/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/hortusfox_error.log
    CustomLog \${APACHE_LOG_DIR}/hortusfox_access.log combined
</VirtualHost>
EOF
chown -R www-data:www-data /opt/hortusfox
$STD a2dissite 000-default
$STD a2ensite hortusfox
$STD a2enmod rewrite
systemctl restart apache2
msg_ok "Apache configured"

motd_ssh
customize
cleanup_lxc
