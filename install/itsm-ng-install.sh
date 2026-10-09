#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Florianb63
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://itsm-ng.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_mariadb
msg_info "Loading timezone data"
mariadb-tzinfo-to-sql /usr/share/zoneinfo | mariadb mysql
msg_ok "Loaded timezone data"
MARIADB_DB_NAME="itsmng_db" MARIADB_DB_USER="itsmng" MARIADB_DB_EXTRA_GRANTS="GRANT SELECT ON \`mysql\`.\`time_zone_name\`" setup_mariadb_db

msg_info "Installing ITSM-NG"
setup_deb822_repo \
  "itsm-ng" \
  "http://deb.itsm-ng.org/pubkey.gpg" \
  "http://deb.itsm-ng.org/$(get_os_info id)/" \
  "$(get_os_info codename)"
$STD apt install -y itsm-ng
cd /usr/share/itsm-ng
$STD php bin/console db:install --db-name="$MARIADB_DB_NAME" --db-user="$MARIADB_DB_USER" --db-password="$MARIADB_DB_PASS" --no-interaction
$STD a2dissite 000-default.conf
echo "* * * * * www-data php /usr/share/itsm-ng/front/cron.php" | crontab -
msg_ok "Installed ITSM-NG"

msg_info "Setting permissions"
chown -R www-data:www-data /var/lib/itsm-ng
mkdir -p /usr/share/itsm-ng/css/palettes
chown -R www-data:www-data /usr/share/itsm-ng/css
chown -R www-data:www-data /usr/share/itsm-ng/css_compiled
chown www-data:www-data /etc/itsm-ng/config_db.php
msg_ok "Set permissions"

msg_info "Configuring PHP"
PHP_VERSION=$(ls /etc/php/ | grep -E '^[0-9]+\.[0-9]+$' | head -n 1)
PHP_INI="/etc/php/$PHP_VERSION/apache2/php.ini"
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 20M/' $PHP_INI
sed -i 's/^post_max_size = .*/post_max_size = 20M/' $PHP_INI
sed -i 's/^max_execution_time = .*/max_execution_time = 60/' $PHP_INI
sed -i 's/^[;]*max_input_vars *=.*/max_input_vars = 5000/' "$PHP_INI"
sed -i 's/^memory_limit = .*/memory_limit = 256M/' $PHP_INI
sed -i 's/^;\?\s*session.cookie_httponly\s*=.*/session.cookie_httponly = On/' $PHP_INI
systemctl restart apache2
rm -rf /usr/share/itsm-ng/install
msg_ok "Configured PHP"

motd_ssh
customize
cleanup_lxc
