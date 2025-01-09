#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  git \
  sudo \
  mc \
  apache2 \
  php8.2-{apcu,cli,common,curl,gd,imap,ldap,mysql,xmlrpc,xml,mbstring,bcmath,intl,zip,redis,bz2,soap} \
  php-cas \
  libapache2-mod-php \
  mariadb-server
msg_ok "Installed Dependencies"

msg_info "Setting up database"
DB_NAME=glpi_db
DB_USER=glpi
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql mysql
mysql -u root -e "CREATE DATABASE $DB_NAME;"
mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -u root -e "GRANT SELECT ON \`mysql\`.\`time_zone_name\` TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
    echo "GLPI Database Credentials"
    echo "Database: $DB_NAME"
    echo "Username: $DB_USER"
    echo "Password: $DB_PASS"
} >> ~/glpi_db.creds
msg_ok "Set up database"

msg_info "Installing GLPi"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep '"tag_name"' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
wget -q "https://github.com/glpi-project/glpi/releases/download/${RELEASE}/glpi-${RELEASE}.tgz"
$STD tar -xzvf glpi-${RELEASE}.tgz
cd /opt/glpi
$STD php bin/console db:install --db-name=$DB_NAME --db-user=$DB_USER --db-password=$DB_PASS --no-interaction
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed GLPi"

msg_info "Setting Downstream file"
cat <<EOF > /opt/glpi/inc/downstream.php
<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');
if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
    require_once GLPI_CONFIG_DIR . '/local_define.php';
}
EOF

mv /opt/glpi/config /etc/glpi
mv /opt/glpi/files /var/lib/glpi
mv /var/lib/glpi/_log /var/log/glpi

cat <<EOF > /etc/glpi/local_define.php
<?php
define('GLPI_VAR_DIR', '/var/lib/glpi');
define('GLPI_DOC_DIR', GLPI_VAR_DIR);
define('GLPI_CRON_DIR', GLPI_VAR_DIR . '/_cron');
define('GLPI_DUMP_DIR', GLPI_VAR_DIR . '/_dumps');
define('GLPI_GRAPH_DIR', GLPI_VAR_DIR . '/_graphs');
define('GLPI_LOCK_DIR', GLPI_VAR_DIR . '/_lock');
define('GLPI_PICTURE_DIR', GLPI_VAR_DIR . '/_pictures');
define('GLPI_PLUGIN_DOC_DIR', GLPI_VAR_DIR . '/_plugins');
define('GLPI_RSS_DIR', GLPI_VAR_DIR . '/_rss');
define('GLPI_SESSION_DIR', GLPI_VAR_DIR . '/_sessions');
define('GLPI_TMP_DIR', GLPI_VAR_DIR . '/_tmp');
define('GLPI_UPLOAD_DIR', GLPI_VAR_DIR . '/_uploads');
define('GLPI_CACHE_DIR', GLPI_VAR_DIR . '/_cache');
define('GLPI_LOG_DIR', '/var/log/glpi');
EOF
msg_ok "Configured Downstream file"

msg_info "Setting Folder and File Permissions"
chown root:root /opt/glpi/ -R
chown www-data:www-data /etc/glpi -R
chown www-data:www-data /var/lib/glpi -R
chown www-data:www-data /var/log/glpi -R
chown www-data:www-data /opt/glpi/marketplace -Rf
find /opt/glpi/ -type f -exec chmod 0644 {} \;
find /opt/glpi/ -type d -exec chmod 0755 {} \;
find /etc/glpi -type f -exec chmod 0644 {} \;
find /etc/glpi -type d -exec chmod 0755 {} \;
find /var/lib/glpi -type f -exec chmod 0644 {} \;
find /var/lib/glpi -type d -exec chmod 0755 {} \;
find /var/log/glpi -type f -exec chmod 0644 {} \;
find /var/log/glpi -type d -exec chmod 0755 {} \;
msg_ok "Configured Folder and File Permissions"

msg_info "Setup Service"
cat <<EOF >/etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /opt/glpi/public

    <Directory /opt/glpi/public>
        Require all granted
        RewriteEngine On
        RewriteCond %{HTTP:Authorization} ^(.+)$
        RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined
</VirtualHost>
EOF
$STD a2dissite 000-default.conf
$STD a2enmod rewrite
$STD a2ensite glpi.conf
msg_ok "Setup Service"

msg_info "Setup Cronjob"
echo "* * * * * php /opt/glpi/front/cron.php" | crontab -
msg_ok "Setup Cronjob"

msg_info "Update PHP Params"
PHP_VERSION=$(ls /etc/php/ | grep -E '^[0-9]+\.[0-9]+$' | head -n 1)
PHP_INI="/etc/php/$PHP_VERSION/apache2/php.ini"
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 20M/' $PHP_INI
sed -i 's/^post_max_size = .*/post_max_size = 20M/' $PHP_INI
sed -i 's/^max_execution_time = .*/max_execution_time = 60/' $PHP_INI
sed -i 's/^max_input_vars = .*/max_input_vars = 5000/' $PHP_INI
sed -i 's/^memory_limit = .*/memory_limit = 256M/' $PHP_INI
sed -i 's/^;\?\s*session.cookie_httponly\s*=.*/session.cookie_httponly = On/' $PHP_INI
systemctl restart apache2
msg_ok "Update PHP Params"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/glpi/install
rm -rf /opt/glpi-${RELEASE}.tgz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
