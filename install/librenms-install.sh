#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.librenms.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  acl \
  fping \
  graphviz \
  imagemagick \
  mtr-tiny \
  nginx \
  nmap \
  rrdtool \
  snmp \
  snmpd \
  whois
msg_ok "Installed Dependencies"

msg_info "Installing Python Dependencies"
$STD apt install -y \
  python3-dotenv \
  python3-pymysql \
  python3-redis \
  python3-setuptools \
  python3-systemd \
  python3-pip
msg_ok "Installed Python Dependencies"

PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="gmp,mysql,snmp" setup_php
setup_mariadb
setup_composer
PYTHON_VERSION="3.13" setup_uv
MARIADB_DB_NAME="librenms" MARIADB_DB_USER="librenms" MARIADB_DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)" setup_mariadb_db
fetch_and_deploy_gh_release "librenms" "librenms/librenms"

msg_info "Configuring LibreNMS"
$STD useradd librenms -d /opt/librenms -M -r -s "$(which bash)"
mkdir -p /opt/librenms/{rrd,logs,bootstrap/cache,storage,html}
cd /opt/librenms
APP_KEY=$(openssl rand -base64 40 | tr -dc 'a-zA-Z0-9')
$STD uv venv .venv
$STD source .venv/bin/activate
$STD uv pip install -r requirements.txt
cat <<EOF >/opt/librenms/.env
DB_DATABASE=${MARIADB_DB_NAME}
DB_USERNAME=${MARIADB_DB_USER}
DB_PASSWORD=${MARIADB_DB_PASS}
APP_KEY=${APP_KEY}
EOF
chown -R librenms:librenms /opt/librenms
chmod 771 /opt/librenms
chmod -R ug=rwX /opt/librenms/bootstrap/cache /opt/librenms/storage /opt/librenms/logs /opt/librenms/rrd
msg_ok "Configured LibreNMS"

msg_info "Configure MariaDB"
sed -i "/\[mysqld\]/a innodb_file_per_table=1\nlower_case_table_names=0" /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl enable -q --now mariadb
msg_ok "Configured MariaDB"

msg_info "Configure PHP-FPM"
cp /etc/php/8.4/fpm/pool.d/www.conf /etc/php/8.4/fpm/pool.d/librenms.conf
sed -i "s/\[www\]/\[librenms\]/g" /etc/php/8.4/fpm/pool.d/librenms.conf
sed -i "s/user = www-data/user = librenms/g" /etc/php/8.4/fpm/pool.d/librenms.conf
sed -i "s/group = www-data/group = librenms/g" /etc/php/8.4/fpm/pool.d/librenms.conf
sed -i "s/listen = \/run\/php\/php8.4-fpm.sock/listen = \/run\/php-fpm-librenms.sock/g" /etc/php/8.4/fpm/pool.d/librenms.conf
msg_ok "Configured PHP-FPM"

msg_info "Configure Nginx"
IP_ADDR=$(hostname -I | awk '{print $1}')
cat >/etc/nginx/sites-enabled/librenms <<'EOF'
server {
 listen      80;
 server_name ${IP_ADDR};
 root        /opt/librenms/html;
 index       index.php;

 charset utf-8;
 gzip on;
 gzip_types text/css application/javascript text/javascript application/x-javascript image/svg+xml text/plain text/xsd text/xsl text/xml image/x-icon;
 location / {
  try_files $uri $uri/ /index.php?$query_string;
 }
 location ~ [^/]\.php(/|$) {
  fastcgi_pass unix:/run/php-fpm-librenms.sock;
  fastcgi_split_path_info ^(.+\.php)(/.+)$;
  include fastcgi.conf;
 }
 location ~ /\.(?!well-known).* {
  deny all;
 }
}
EOF
rm /etc/nginx/sites-enabled/default
$STD systemctl reload nginx
systemctl restart php8.4-fpm
msg_ok "Configured Nginx"

msg_info "Configure Services"
ln -s /opt/librenms/lnms /usr/bin/lnms
mkdir -p /etc/bash_completion.d/
cp /opt/librenms/misc/lnms-completion.bash /etc/bash_completion.d/
cp /opt/librenms/snmpd.conf.example /etc/snmp/snmpd.conf

APP_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
APP_USER="admin"
{
  echo "LibreNMS Credentials"
  echo "Username: ${APP_USER}"
  echo "Password: ${APP_PASSWORD}"
} >>~/librenms.creds

$STD su - librenms -s /bin/bash -c "cd /opt/librenms && COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev"
$STD su - librenms -s /bin/bash -c "cd /opt/librenms && php8.4 artisan migrate --force"
$STD su - librenms -s /bin/bash -c "cd /opt/librenms && php8.4 artisan key:generate --force"
$STD su - librenms -s /bin/bash -c "cd /opt/librenms && lnms db:seed --force"
$STD su - librenms -s /bin/bash -c "cd /opt/librenms && lnms user:add -p ${APP_PASSWORD} ${APP_USER} --role=admin"

RANDOM_STRING=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9')
sed -i "s/RANDOMSTRINGHERE/$RANDOM_STRING/g" /etc/snmp/snmpd.conf
echo "SNMP Community String: $RANDOM_STRING" >>~/librenms.creds
curl -qso /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro
chmod +x /usr/bin/distro
systemctl enable -q --now snmpd

cp /opt/librenms/dist/librenms.cron /etc/cron.d/librenms
cp /opt/librenms/dist/librenms-scheduler.service /opt/librenms/dist/librenms-scheduler.timer /etc/systemd/system/

systemctl enable -q --now librenms-scheduler.timer
cp /opt/librenms/misc/librenms.logrotate /etc/logrotate.d/librenms
msg_ok "Configured Services"

motd_ssh
customize
cleanup_lxc
