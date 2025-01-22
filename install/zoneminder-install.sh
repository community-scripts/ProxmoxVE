#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: [YourUserName]
# License: MIT
# Source: [SOURCE_URL]

# Import Functions und Setup
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Installing Dependencies with the 3 core dependencies (curl;sudo;mc)
# plus any additional packages you need
msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  apache2 \
  mariadb-server \
  libapache2-mod-php
msg_ok "Installed Dependencies"

# Install / set up MySQL
msg_info "Install / set up MySQL"
APPLICATION="ZoneMinder"
APP_NAME="ZoneMinder"
DB_NAME="zm"
DB_USER="zmuser"
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)

$STD mysql -u root -e "CREATE DATABASE $DB_NAME;"
$STD mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
$STD mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"

{
    echo "Database Credentials"
    echo "Database User: $DB_USER"
    echo "Database Password: $DB_PASS"
    echo "Database Name: $DB_NAME"
} >> ~/$APP_NAME.creds
msg_ok "MySQL setup completed"

# Enable the ZoneMinder PPA (iconnor/zoneminder-1.36) and install
msg_info "Enabling ZoneMinder PPA and installing ZoneMinder"
$STD apt install -y software-properties-common
$STD add-apt-repository ppa:iconnor/zoneminder-1.36 -y
$STD apt update
$STD apt-get install -y zoneminder
msg_ok "ZoneMinder installed"

# Enable Apache modules & ZoneMinder service
msg_info "Configuring Apache and ZoneMinder"
a2enmod rewrite
a2enconf zoneminder
systemctl restart apache2
systemctl enable zoneminder
systemctl start zoneminder
msg_ok "Apache and ZoneMinder configured and running"

# Cleanup
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
