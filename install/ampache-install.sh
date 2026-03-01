#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ampache/ampache

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt install -y \
  flac \
  vorbis-tools \
  lame \
  ffmpeg \
  inotify-tools \
  libavcodec-extra \
  libmp3lame-dev \
  libtheora-dev \
  libvorbis-dev \
  libvpx-dev
msg_ok "Installed dependencies"

PHP_VERSION="8.4" PHP_APACHE="YES" setup_php
setup_mariadb
MARIADB_DB_USER="ampache" MARIADB_DB_NAME="ampache" setup_mariadb_db

fetch_and_deploy_gh_release "ampache" "ampache/ampache" "prebuild" "latest" "/opt/ampache" "ampache-*_all_php8.4.zip"

msg_info "Setting up Ampache"
rm -rf /var/www/html
ln -s /opt/ampache/public /var/www/html
mv /opt/ampache/public/rest/.htaccess.dist /opt/ampache/public/rest/.htaccess
mv /opt/ampache/public/play/.htaccess.dist /opt/ampache/public/play/.htaccess
cp /opt/ampache/config/ampache.cfg.php.dist /opt/ampache/config/ampache.cfg.php
chmod 664 /opt/ampache/public/rest/.htaccess /opt/ampache/public/play/.htaccess
msg_ok "Set up Ampache"

msg_info "Configuring Database Connection"
sed -i -e 's|^database_hostname = .*|database_hostname = "localhost"|' \
  -e 's|^database_name = .*|database_name = "ampache"|' \
  -e 's|^database_username = .*|database_username = "ampache"|' \
  -e "s|^database_password = .*|database_password = \"${MARIADB_DB_PASS}\"|" /opt/ampache/config/ampache.cfg.php
chown -R www-data:www-data /opt/ampache
msg_ok "Configured Database Connection"

msg_info "Importing Database Schema"
mariadb -u ampache -p"${MARIADB_DB_PASS}" ampache </opt/ampache/resources/sql/ampache.sql
msg_ok "Imported Database Schema"

msg_info "Configuring PHP"
sed -i -e 's/upload_max_filesize = .*/upload_max_filesize = 100M/' \
  -e 's/post_max_size = .*/post_max_size = 100M/' \
  -e 's/max_execution_time = .*/max_execution_time = 600/' \
  -e 's/memory_limit = .*/memory_limit = 512M/' /etc/php/8.4/apache2/php.ini
$STD a2enmod rewrite
$STD systemctl restart apache2
msg_ok "Configured PHP"

motd_ssh
customize
cleanup_lxc
