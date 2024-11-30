#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: kristocopani
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    curl \
    mc \
    sudo
curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ bookworm main" >/etc/apt/sources.list.d/php.list
$STD apt-get update
$STD apt-get install -y \
    apache2 \
    php8.3 \
    php8.3-cli \
    libapache2-mod-php8.3 \
    php8.3-{bcmath,intl,curl,zip,gd,xml,mbstring,mysql} \
    mariadb-server \
    composer
msg_ok "Installed Dependencies"

msg_info "Setting up database"
DB_NAME=firefly
DB_USER=firefly
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
MYSQL_VERSION=$(mysql --version | grep -oP 'Distrib \K[0-9]+\.[0-9]+\.[0-9]+')
mysql -u root -e "CREATE DATABASE $DB_NAME;"
mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
    echo "Firefly-Credentials"
    echo "Firefly Database User: $DB_USER"
    echo "Firefly Database Password: $DB_PASS"
    echo "Firefly Database Name: $DB_NAME"
} >> ~/firefly.creds
msg_ok "Set up database"



msg_info "Installing Firefly III (Patience)"
RELEASE=$(curl -s https://api.github.com/repos/firefly-iii/firefly-iii/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
cd /opt
wget -q "https://github.com/firefly-iii/firefly-iii/releases/download/${RELEASE}/FireflyIII-${RELEASE}.tar.gz"
mkdir -p /opt/firefly-iii
tar -xzf FireflyIII-${RELEASE}.tar.gz -C /opt/firefly-iii
chown -R www-data:www-data /opt/firefly-iii
chmod -R 775 /opt/firefly-iii/storage
cd /opt/firefly-iii
cp .env.example .env
sed -i "s/DB_HOST=.*/DB_HOST=localhost/" /opt/firefly-iii/.env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" /opt/firefly-iii/.env
echo "export COMPOSER_ALLOW_SUPERUSER=1" >> ~/.bashrc
source ~/.bashrc
$STD composer install --no-dev --no-plugins --no-interaction
$STD php artisan firefly-iii:upgrade-database --no-interaction --force
$STD php artisan firefly-iii:correct-database --no-interaction --force
$STD php artisan firefly-iii:report-integrity --no-interaction --force
$STD php artisan firefly-iii:laravel-passport-keys --no-interaction --force
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Firefly III"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/firefly-iii.conf
<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  DocumentRoot /opt/firefly-iii/public/

   <Directory /opt/firefly-iii/public>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
  
    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined

</VirtualHost>
EOF
$STD a2enmod php8.3
$STD a2enmod rewrite
$STD a2ensite firefly-iii.conf
$STD a2dissite 000-default.conf  
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/FireflyIII-${RELEASE}.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"