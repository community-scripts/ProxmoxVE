#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: connorjfarrell
# License: MIT
# Source: https://zoneminder.readthedocs.io/en/latest/installationguide/ubuntu.html#ubuntu-22-04-jammy

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
  apache2 \
  mariadb-server \
  libapache2-mod-php
msg_ok "Installed Dependencies"

msg_info "Pre-seeding dbconfig-common for ZoneMinder"

ROOT_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
ZMPASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)

export DEBIAN_FRONTEND=noninteractive

echo "zoneminder zoneminder/dbconfig-install boolean true"        | debconf-set-selections
echo "zoneminder zoneminder/dbconfig-reinstall boolean false"     | debconf-set-selections
echo "zoneminder zoneminder/mysql/admin-user string root"         | debconf-set-selections
echo "zoneminder zoneminder/mysql/admin-pass password $ROOT_PASS" | debconf-set-selections
echo "zoneminder zoneminder/mysql/app-pass password $ZMPASS"      | debconf-set-selections
echo "zoneminder zoneminder/app-password-confirm password $ZMPASS"| debconf-set-selections

{
    echo "ZoneMinder Database Credentials"
    echo "MySQL Root Password: $ROOT_PASS"
    echo "ZoneMinder DB User: zmuser"
    echo "ZoneMinder DB Pass: $ZMPASS"
    echo "ZoneMinder DB Name: zm"
} >> ~/zoneminder.creds
msg_ok "dbconfig pre-seeding complete"

msg_info "Enabling ZoneMinder PPA and installing ZoneMinder"
$STD apt install -y software-properties-common
$STD add-apt-repository ppa:iconnor/zoneminder-1.36 -y
$STD apt update
$STD apt-get install -y zoneminder
msg_ok "ZoneMinder installed"

msg_info "Configuring Apache and ZoneMinder"
a2enmod rewrite
a2enconf zoneminder
systemctl restart apache2
systemctl enable zoneminder
systemctl start zoneminder
msg_ok "Apache and ZoneMinder configured and running"

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
