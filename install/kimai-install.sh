#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.kimai.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  apt-transport-https \
  apache2 \
  git \
  expect \
  composer \
  lsb-release
msg_ok "Installed Dependencies"

setup_mysql

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
  php8.4-{gd,mysql,mbstring,bcmath,xml,curl,zip,intl} \
  libapache2-mod-php8.4
msg_ok "Installed PHP"

msg_info "Setting up database"
DB_NAME=kimai_db
DB_USER=kimai
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
MYSQL_VERSION=$(mysql --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
$STD mysql -u root -e "CREATE DATABASE $DB_NAME;"
$STD mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "Kimai-Credentials"
  echo "Kimai Database User: $DB_USER"
  echo "Kimai Database Password: $DB_PASS"
  echo "Kimai Database Name: $DB_NAME"
} >>~/kimai.creds
msg_ok "Set up database"

msg_info "Installing Kimai (Patience)"
RELEASE=$(curl -fsSL https://api.github.com/repos/kimai/kimai/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
curl -fsSL "https://github.com/kimai/kimai/archive/refs/tags/${RELEASE}.zip" -o "${RELEASE}".zip
$STD unzip "${RELEASE}".zip
mv kimai-"${RELEASE}" /opt/kimai
cd /opt/kimai
echo "export COMPOSER_ALLOW_SUPERUSER=1" >>~/.bashrc
source ~/.bashrc
$STD composer install --no-dev --optimize-autoloader --no-interaction
cp .env.dist .env
sed -i "/^DATABASE_URL=/c\DATABASE_URL=mysql://$DB_USER:$DB_PASS@127.0.0.1:3306/$DB_NAME?charset=utf8mb4&serverVersion=$MYSQL_VERSION" /opt/kimai/.env
$STD bin/console kimai:install -n
$STD expect <<EOF
set timeout -1
log_user 0

spawn bin/console kimai:user:create admin admin@helper-scripts.com ROLE_SUPER_ADMIN

expect "Please enter the password:"
send "helper-scripts.com\r"

expect eof
EOF
$STD composer update --no-interaction
cat <<EOF >/opt/kimai/config/packages/local.yaml
kimai:
    timesheet:
        rounding:
            default:
                begin: 15
                end: 15

admin_lte:
    options:
        default_avatar: build/apple-touch-icon.png
EOF

echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Kimai"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/kimai.conf
<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  DocumentRoot /opt/kimai/public/

   <Directory /opt/kimai/public>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
  
    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined

</VirtualHost>
EOF
$STD a2ensite kimai.conf
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

msg_info "Setup Permissions"
chown -R :www-data /opt/*
chmod -R g+r /opt/*
chmod -R g+rw /opt/*
chown -R www-data:www-data /opt/*
chmod -R 777 /opt/*
msg_ok "Setup Permissions"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "${RELEASE}".zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
