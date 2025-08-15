#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Don Locke (DonLocke)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wavelog/wavelog

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.3" PHP_MODULE="mysql" PHP_APACHE="YES" PHP_MAX_EXECUTION_TIME="600" setup_php
setup_mariadb
fetch_and_deploy_gh_release "wavelog" "wavelog/wavelog" "tarball"

msg_info "Setting up Database"
DB_NAME=wavelog
DB_USER=waveloguser
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "Wavelog-Credentials"
  echo "Wavelog Database User: $DB_USER"
  echo "Wavelog Database Password: $DB_PASS"
  echo "Wavelog Database Name: $DB_NAME"
} >>~/wavelog.creds
msg_ok "Set up database"

msg_info "Configuring Wavelog"
chown -R www-data:www-data /opt/wavelog/
find /opt/wavelog/ -type d -exec chmod 755 {} \;
find /opt/wavelog/ -type f -exec chmod 664 {} \;
msg_ok "Configured Wavelog"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/wavelog.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /opt/wavelog

    <Directory /opt/wavelog>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined
</VirtualHost>
EOF
$STD a2ensite wavelog.conf
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
