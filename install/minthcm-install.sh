#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MintHCM
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/minthcm/minthcm
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.2"
PHP_APACHE="YES" PHP_MODULE="mysql,redis" PHP_FPM="YES" setup_php
setup_composer
setup_mariadb
$STD mariadb -u root -e "SET GLOBAL sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'"

fetch_and_deploy_gh_release "MintHCM" "minthcm/minthcm" "tarball" "latest" "/var/www/MintHCM"

msg_info "Configuring MintHCM"
mkdir -p /etc/php/${PHP_VERSION}/mods-available
cp /var/www/MintHCM/docker/config/000-default.conf /etc/apache2/sites-available/000-default.conf
cp /var/www/MintHCM/docker/config/php-minthcm.ini /etc/php/${PHP_VERSION}/mods-available/php-minthcm.ini
mkdir -p "/etc/php/${PHP_VERSION}/cli/conf.d" "/etc/php/${PHP_VERSION}/apache2/conf.d"
ln -s "/etc/php/${PHP_VERSION}/mods-available/php-minthcm.ini" "/etc/php/${PHP_VERSION}/cli/conf.d/20-minthcm.ini"
ln -s "/etc/php/${PHP_VERSION}/mods-available/php-minthcm.ini" "/etc/php/${PHP_VERSION}/apache2/conf.d/20-minthcm.ini"
chown -R www-data:www-data /var/www/MintHCM
find /var/www/MintHCM -type d -exec chmod 755 {} \;
find /var/www/MintHCM -type f -exec chmod 644 {} \;
mkdir -p /var/www/script
cp /var/www/MintHCM/docker/script/generate_config.php /var/www/script/generate_config.php
cp /var/www/MintHCM/docker/.env /var/www/script/.env
chown -R www-data:www-data /var/www/script
$STD a2enmod rewrite
$STD a2enmod headers
$STD systemctl restart apache2
msg_ok "Configured MintHCM"

msg_info "Setting up Elasticsearch"
setup_deb822_repo \
  "elasticsearch" \
  "https://artifacts.elastic.co/GPG-KEY-elasticsearch" \
  "https://artifacts.elastic.co/packages/7.x/apt" \
  "stable"
$STD apt install -y elasticsearch
echo "-Xms2g" >>/etc/elasticsearch/jvm.options
echo "-Xmx2g" >>/etc/elasticsearch/jvm.options
$STD /usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-attachment -b
systemctl enable -q --now elasticsearch
msg_ok "Set up Elasticsearch"

msg_info "Configuring Database"
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE USER 'minthcm'@'localhost' IDENTIFIED BY '${DB_PASS}';"
$STD mariadb -u root -e "GRANT ALL ON *.* TO 'minthcm'@'localhost'; FLUSH PRIVILEGES;"
sed -i "s/^DB_HOST=.*/DB_HOST=localhost/" /var/www/script/.env
sed -i "s/^DB_USER=.*/DB_USER=minthcm/" /var/www/script/.env
sed -i "s/^DB_PASS=.*/DB_PASS=$DB_PASS/" /var/www/script/.env
sed -i "s/^ELASTICSEARCH_HOST=.*/ELASTICSEARCH_HOST=localhost/" /var/www/script/.env
msg_ok "Configured Database"

msg_info "Generating configuration file"
set -a
source /var/www/script/.env
set +a
$STD php /var/www/script/generate_config.php
msg_ok "Generated configuration file"

msg_info "Installing MintHCM"
cd /var/www/MintHCM
$STD sudo -u www-data php MintCLI install </var/www/MintHCM/configMint4
printf "*    *    *    *    *     cd /var/www/MintHCM/legacy; php -f cron.php > /dev/null 2>&1\n" >/var/spool/cron/crontabs/www-data
service cron start
rm -f /var/www/MintHCM/configMint4
msg_ok "Installed MintHCM"

motd_ssh
customize
cleanup_lxc
