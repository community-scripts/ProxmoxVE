#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mariadb.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing MariaDB"
$STD apk add --no-cache mariadb mariadb-client
$STD rc-update add mariadb default
msg_ok "Installed MariaDB"

msg_info "Configuring MariaDB"
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql >/dev/null 2>&1
$STD rc-service mariadb start
msg_ok "MariaDB Configured"

read -r -p "${TAB3}Would you like to install Adminer with lighttpd? <y/N>: " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing Adminer and dependencies"
  $STD apk add --no-cache \
    lighttpd \
    lighttpd-openrc \
    php83 \
    php83-cgi \
    php83-common \
    php83-curl \
    php83-gd \
    php83-mbstring \
    php83-mysqli \
    php83-mysqlnd \
    php83-openssl \
    php83-zip \
    php83-session \
    jq

  sed -i 's|# *include "mod_fastcgi.conf"|include "mod_fastcgi.conf"|' /etc/lighttpd/lighttpd.conf
  mkdir -p /var/www/localhost/htdocs
  ADMINER_VERSION=$(curl -fsSL https://api.github.com/repos/vrana/adminer/releases/latest | jq -r '.tag_name' | sed 's/^v//')
  curl -fsSL "https://github.com/vrana/adminer/releases/download/v${ADMINER_VERSION}/adminer-${ADMINER_VERSION}.php" -o /var/www/localhost/htdocs/adminer.php
  chown lighttpd:lighttpd /var/www/localhost/htdocs/adminer.php
  chmod 755 /var/www/localhost/htdocs/adminer.php
  msg_ok "Adminer Installed"

  msg_info "Starting Lighttpd"
  $STD rc-update add lighttpd default
  $STD rc-service lighttpd restart
  msg_ok "Lighttpd Started"
fi

motd_ssh
customize

msg_info "Cleaning up"
msg_ok "Cleaned"
