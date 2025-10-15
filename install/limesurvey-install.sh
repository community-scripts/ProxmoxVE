#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://community.limesurvey.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.3" PHP_APACHE="YES" PHP_FPM="YES" PHP_MODULE="imap,ldap,mysql" setup_php
setup_mariadb

msg_info "Configuring MariaDB Database"
DB_NAME=limesurvey_db
DB_USER=limesurvey
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
    echo "LimeSurvey-Credentials"
    echo "LimeSurvey Database User: $DB_USER"
    echo "LimeSurvey Database Password: $DB_PASS"
    echo "LimeSurvey Database Name: $DB_NAME"
} >>~/limesurvey.creds
msg_ok "Configured MariaDB Database"

msg_info "Setting up LimeSurvey"
temp_file=$(mktemp)
RELEASE=$(curl -s https://community.limesurvey.org/downloads/ | grep -oE 'https://download\.limesurvey\.org/latest-master/limesurvey[0-9.+]+\.zip' | head -n1)
curl -fsSL "$RELEASE" -o "$temp_file"
unzip -q "$temp_file" -d /opt

cat <<EOF >/etc/apache2/sites-enabled/000-default.conf
<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  DocumentRoot /opt/limesurvey
  DirectoryIndex index.php index.html index.cgi index.pl index.xhtml
  Options +ExecCGI

  <Directory /opt/limesurvey/>
    Options FollowSymLinks
    Require all granted
    AllowOverride All
  </Directory>

  <Location />
    Require all granted
  </Location>

  ErrorLog /var/log/apache2/error.log
  CustomLog /var/log/apache2/access.log combined
</VirtualHost>
EOF
chown -R www-data:www-data "/opt/limesurvey"
chmod -R 750 "/opt/limesurvey"
systemctl reload apache2
msg_ok "Set up LimeSurvey"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "$temp_file"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
