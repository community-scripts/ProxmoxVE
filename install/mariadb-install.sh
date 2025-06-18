#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
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

setup_mariadb

msg_info "Setup MariaDB"
sed -i 's/^# *\(port *=.*\)/\1/' /etc/mysql/my.cnf
sed -i 's/^bind-address/#bind-address/g' /etc/mysql/mariadb.conf.d/50-server.cnf
msg_ok "Setup MariaDB"

read -r -p "${TAB3}Would you like to add PhpMyAdmin? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing phpMyAdmin"
  $STD apt-get install -y \
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

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
