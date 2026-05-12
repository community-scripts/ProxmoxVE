#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://matomo.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y caddy
msg_ok "Installed Dependencies"

mkdir -p /opt/matomo

PHP_VERSION="8.3" PHP_FPM="YES" PHP_MODULES="pdo_mysql,gd,mbstring,xml,curl,intl,zip,ldap" setup_php
setup_mariadb
MARIADB_DB_NAME="matomo" MARIADB_DB_USER="matomo" setup_mariadb_db

msg_info "Allowing Local TCP Database Access"
$STD mariadb -u root -e "CREATE USER IF NOT EXISTS '$MARIADB_DB_USER'@'127.0.0.1' IDENTIFIED BY '$MARIADB_DB_PASS';"
$STD mariadb -u root -e "ALTER USER '$MARIADB_DB_USER'@'127.0.0.1' IDENTIFIED BY '$MARIADB_DB_PASS';"
$STD mariadb -u root -e "GRANT ALL ON \`$MARIADB_DB_NAME\`.* TO '$MARIADB_DB_USER'@'127.0.0.1';"
$STD mariadb -u root -e "FLUSH PRIVILEGES;"
msg_ok "Allowed Local TCP Database Access"

fetch_and_deploy_gh_release "matomo" "matomo-org/matomo" "prebuild" "latest" "/opt/matomo" "matomo-*.zip"

msg_info "Setting up Matomo"
if [[ -d /opt/matomo/matomo ]]; then
  rm -rf /opt/matomo/tmp "/opt/matomo/How to install Matomo.html"
  find /opt/matomo/matomo -mindepth 1 -maxdepth 1 -exec mv -t /opt/matomo {} +
  rm -rf /opt/matomo/matomo
fi
mkdir -p /opt/matomo/tmp
chown -R www-data:www-data /opt/matomo
chmod -R 755 /opt/matomo/tmp
msg_ok "Set up Matomo"

msg_info "Configuring Caddy"
PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
cat <<EOF >/etc/caddy/Caddyfile
:80 {
    root * /opt/matomo
    @blocked path /config /config/* /tmp /tmp/* /.* /.*/*
    respond @blocked 403
    php_fastcgi unix//run/php/php${PHP_VER}-fpm.sock
    file_server
    encode gzip
}
EOF
usermod -aG www-data caddy
msg_ok "Configured Caddy"

systemctl enable -q --now php${PHP_VER}-fpm
systemctl restart caddy

motd_ssh
customize
cleanup_lxc
