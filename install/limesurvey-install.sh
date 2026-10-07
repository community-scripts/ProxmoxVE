#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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

PHP_VERSION="8.3" PHP_APACHE="YES" PHP_FPM="YES" PHP_MODULE="imap,ldap" setup_php
setup_mariadb

MARIADB_DB_NAME="limesurvey_db" MARIADB_DB_USER="limesurvey" setup_mariadb_db

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
$STD a2enmod rewrite
systemctl reload apache2
rm -rf "$temp_file"
msg_ok "Set up LimeSurvey"

motd_ssh
customize
cleanup_lxc
