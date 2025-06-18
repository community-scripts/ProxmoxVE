#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pelican-dev/panel

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
  php8.4-{gd,mysql,mbstring,bcmath,xml,curl,zip,intl,sqlite3,fpm} \
  libapache2-mod-php8.4
msg_info "Installed PHP"

msg_info "Setting up MariaDB"
DB_NAME=panel
DB_USER=pelican
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "Pelican Panel-Credentials"
  echo "Pelican Panel Database User: $DB_USER"
  echo "Pelican Panel Database Password: $DB_PASS"
  echo "Pelican Panel Database Name: $DB_NAME"
} >>~/pelican-panel.creds
msg_ok "Set up MariaDB"

msg_info "Installing Pelican Panel"
RELEASE=$(curl -fsSL https://api.github.com/repos/pelican-dev/panel/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
mkdir /opt/pelican-panel
cd /opt/pelican-panel
curl -fsSL "https://github.com/pelican-dev/panel/releases/download/v${RELEASE}/panel.tar.gz" -o "panel.tar.gz"
tar -xzf "panel.tar.gz"
$STD composer install --no-dev --optimize-autoloader --no-interaction
$STD php artisan p:environment:setup
$STD php artisan p:environment:queue-service --no-interaction
echo "* * * * * php /opt/pelican-panel/artisan schedule:run >> /dev/null 2>&1" | crontab -u www-data -
chown -R www-data:www-data /opt/pelican-panel
chmod -R 755 /opt/pelican-panel/storage /opt/pelican-panel/bootstrap/cache/
echo "${RELEASE}" >/opt/"${APPLICATION}"_version.txt
msg_ok "Installed Pelican Panel"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/pelican.conf
<VirtualHost *:80>
    ServerName pelican
    DocumentRoot /opt/pelican-panel/public
    AllowEncodedSlashes On
    php_value upload_max_filesize 100M
    php_value post_max_size 100M

    <Directory /opt/pelican-panel/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/pelican_error.log
    CustomLog /var/log/apache2/pelican_access.log combined
</VirtualHost>
EOF
$STD a2ensite pelican
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "/opt/pelican-panel/panel.tar.gz"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
