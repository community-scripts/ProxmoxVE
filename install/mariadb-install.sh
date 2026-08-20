#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mariadb.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb_based() {
  setup_mariadb

  msg_info "Setup MariaDB"
  sed -i 's/^# *\(port *=.*\)/\1/' /etc/mysql/my.cnf
  sed -i 's/^bind-address/#bind-address/g' /etc/mysql/mariadb.conf.d/50-server.cnf
  msg_ok "Setup MariaDB"

  read -r -p "${TAB3}Would you like to add PhpMyAdmin? <y/N> " prompt
  if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
    msg_info "Installing phpMyAdmin"
    $STD apt install -y \
      apache2 \
      php \
      php-mysqli \
      php-mbstring \
      php-zip \
      php-gd \
      php-json \
      php-curl

    curl -fsSL "https://files.phpmyadmin.net/phpMyAdmin/5.2.2/phpMyAdmin-5.2.2-all-languages.tar.gz" -o "phpMyAdmin-5.2.2-all-languages.tar.gz"
    mkdir -p /var/www/html/phpMyAdmin
    tar xf phpMyAdmin-5.2.2-all-languages.tar.gz --strip-components=1 -C /var/www/html/phpMyAdmin
    cp /var/www/html/phpMyAdmin/config.sample.inc.php /var/www/html/phpMyAdmin/config.inc.php
    SECRET=$(openssl rand -base64 24)
    sed -i "s#\$cfg\['blowfish_secret'\] = '';#\$cfg['blowfish_secret'] = '${SECRET}';#" /var/www/html/phpMyAdmin/config.inc.php
    chmod 660 /var/www/html/phpMyAdmin/config.inc.php
    chown -R www-data:www-data /var/www/html/phpMyAdmin
    systemctl restart apache2
    msg_ok "Installed phpMyAdmin"
  fi
}

setup_alpine() {
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
    sed -i 's|/usr/bin/php-cgi|/usr/bin/php-cgi83|g' /etc/lighttpd/mod_fastcgi.conf
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
}

run_os_setup

motd_ssh
customize
cleanup_lxc
