#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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

setup_mariadb
MARIADB_DB_NAME="hortusfox" MARIADB_DB_USER="hortusfox" setup_mariadb_db
PHP_VERSION="8.3" PHP_APACHE="YES" setup_php
setup_composer
fetch_and_deploy_gh_release "hortusfox" "danielbrendel/hortusfox-web" "tarball"

msg_info "Configuring .env"
cp /opt/hortusfox/.env.example /opt/hortusfox/.env
sed -i "s|^DB_HOST=.*|DB_HOST=localhost|" /opt/hortusfox/.env
sed -i "s|^DB_USER=.*|DB_USER=$MARIADB_DB_USER|" /opt/hortusfox/.env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$MARIADB_DB_PASS|" /opt/hortusfox/.env
sed -i "s|^DB_DATABASE=.*|DB_DATABASE=$MARIADB_DB_NAME|" /opt/hortusfox/.env
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
$STD mariadb -u root -D $MARIADB_DB_NAME -e "INSERT IGNORE INTO AppModel (workspace, language, created_at) VALUES ('Default Workspace', 'en', NOW());"
$STD php asatru plants:attributes
$STD php asatru calendar:classes
ADMIN_EMAIL="admin@example.com"
ADMIN_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)"
ADMIN_HASH=$(php -r "echo password_hash('$ADMIN_PASS', PASSWORD_BCRYPT);")
$STD mariadb -u root -D $MARIADB_DB_NAME -e "INSERT IGNORE INTO UserModel (name, email, password, admin) VALUES ('Admin', '$ADMIN_EMAIL', '$ADMIN_HASH', 1);"
{
  echo ""
  echo "HortusFox-Admin-Creds:"
  echo "E-Mail: $ADMIN_EMAIL"
  echo "Passwort: $ADMIN_PASS"
} >>~/hortusfox.creds
$STD mariadb -u root -D $MARIADB_DB_NAME -e "INSERT IGNORE INTO LocationsModel (name, active, created_at) VALUES ('Home', 1, NOW());"
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
