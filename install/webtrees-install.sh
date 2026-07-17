#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: sudofly
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://webtrees.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  caddy \
  unzip
msg_ok "Installed Dependencies"

PHP_VERSION="8.3" PHP_FPM="YES" PHP_MODULES="bcmath,gd,intl,xml,zip,pdo_mysql,mbstring,curl" setup_php
setup_mariadb
MARIADB_DB_NAME="webtrees" MARIADB_DB_USER="webtrees" setup_mariadb_db
$STD mariadb -u root -e "GRANT ALL ON \`webtrees\`.* TO 'webtrees'@'127.0.0.1' IDENTIFIED BY '${MARIADB_DB_PASS}'; FLUSH PRIVILEGES;"

fetch_and_deploy_gh_release "webtrees" "fisharebest/webtrees" "prebuild" "latest" "/opt/webtrees" "webtrees-*.zip"

msg_info "Setting up Webtrees"
chown -R www-data:www-data /opt/webtrees
msg_ok "Set up Webtrees"

msg_info "Configuring Caddy"
PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
cat <<EOF >/etc/caddy/Caddyfile
:80 {
    root * /opt/webtrees
    php_fastcgi unix//run/php/php${PHP_VER}-fpm.sock
    file_server
    encode gzip
}
EOF
usermod -aG www-data caddy
systemctl enable -q --now php${PHP_VER}-fpm
systemctl restart caddy
msg_ok "Configured Caddy"

msg_info "Automating Webtrees Setup"
cd /opt/webtrees
mkdir -p /opt/webtrees/data
chown -R www-data:www-data /opt/webtrees/data
WT_ADMIN_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c15)
$STD sudo -u www-data php /opt/webtrees/index.php config-ini \
  --dbhost=127.0.0.1 \
  --dbport=3306 \
  --dbuser=webtrees \
  --dbpass="${MARIADB_DB_PASS}" \
  --dbname=webtrees \
  --tblpfx=wt_ \
  --base-url="http://${LOCAL_IP}"
msg_info "Initializing Webtrees database schema"
for i in {1..15}; do
  if curl -sf "http://127.0.0.1/" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
$STD mariadb -u webtrees -p"${MARIADB_DB_PASS}" -h 127.0.0.1 webtrees -e "SHOW TABLES LIKE 'wt_user';" | grep -q wt_user
msg_ok "Initialized Webtrees database schema"
$STD sudo -u www-data php /opt/webtrees/index.php user Admin \
  --create \
  --real-name="Administrator" \
  --email="admin@example.com" \
  --password="${WT_ADMIN_PASS}"
$STD sudo -u www-data php /opt/webtrees/index.php user-setting Admin canadmin 1

cat <<EOF >~/webtrees.creds

Webtrees Admin User: Admin
Webtrees Admin Password: ${WT_ADMIN_PASS}
EOF
msg_ok "Webtrees Setup Automated"

motd_ssh
customize
cleanup_lxc
