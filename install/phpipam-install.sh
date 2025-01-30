#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  mariadb-server \
  apache2 \
  libapache2-mod-php \
  php8.2 php8.2-{fpm,curl,cli,mysql,gd,intl,imap,apcu,pspell,tidy,xmlrpc,mbstring,gmp,xml,ldap,common,snmp} \
  php-pear
msg_ok "Installed Dependencies"

msg_info "Setting up MariaDB"
DB_NAME=phpipam
DB_USER=phpipam
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mysql -u root -e "CREATE DATABASE $DB_NAME;"
$STD mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
$STD mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
    echo "phpIPAM-Credentials"
    echo "phpIPAM Database User: $DB_USER"
    echo "phpIPAM Database Password: $DB_PASS"
    echo "phpIPAM Database Name: $DB_NAME"
} >> ~/phpipam.creds
msg_ok "Set up MariaDB"

msg_info "Installing phpIPAM"
RELEASE=$(curl -s https://api.github.com/repos/phpipam/phpipam/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
cd /opt
wget -q "https://github.com/phpipam/phpipam/releases/download/v${RELEASE}/phpipam-v${RELEASE}.zip"
unzip -q "phpipam-v${RELEASE}.zip"
mysql -u root "${DB_NAME}" < /opt/phpipam/db/SCHEMA.sql
cp /opt/phpipam/config.dist.php /opt/phpipam/config.php
sed -i -e "s/\(\$disable_installer = \).*/\1true;/" \
       -e "s/\(\$db\['user'\] = \).*/\1'$DB_USER';/" \
       -e "s/\(\$db\['pass'\] = \).*/\1'$DB_PASS';/" \
       -e "s/\(\$db\['name'\] = \).*/\1'$DB_NAME';/" \
       /opt/phpipam/config.php
sed -i '/max_execution_time/s/= .*/= 600/' /etc/php/8.2/apache2/php.ini
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed phpIPAM"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/phpipam.conf
<VirtualHost *:80>
    ServerName phpipam
    DocumentRoot /opt/phpipam
    <Directory /opt/phpipam>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/phpipam_error.log
    CustomLog /var/log/apache2/phpipam_access.log combined
</VirtualHost>
EOF
$STD a2ensite phpipam
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "/opt/phpipam-v${RELEASE}.zip"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
