#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.part-db.de/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs
PG_VERSION="16" setup_postgresql
PG_DB_NAME="partdb" PG_DB_USER="partdb" setup_postgresql_db
PHP_VERSION="8.4" PHP_APACHE="YES" PHP_MODULE="xsl" PHP_POST_MAX_SIZE="100M" PHP_UPLOAD_MAX_FILESIZE="100M" setup_php
setup_composer

msg_info "Installing Part-DB (Patience)"
cd /opt
RELEASE=$(get_latest_github_release "Part-DB/Part-DB-server")
curl -fsSL "https://github.com/Part-DB/Part-DB-server/archive/refs/tags/v${RELEASE}.zip" -o "/opt/v${RELEASE}.zip"
$STD unzip "v${RELEASE}.zip"
mv /opt/Part-DB-server-${RELEASE}/ /opt/partdb

cd /opt/partdb/
cp .env .env.local
sed -i "s|DATABASE_URL=\"sqlite:///%kernel.project_dir%/var/app.db\"|DATABASE_URL=\"postgresql://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}?serverVersion=12.19&charset=utf8\"|" .env.local

export COMPOSER_ALLOW_SUPERUSER=1
$STD composer install --no-dev -o --no-interaction
$STD yarn install
$STD yarn build
$STD php bin/console cache:clear
php bin/console doctrine:migrations:migrate -n >~/database-migration-output
chown -R www-data:www-data /opt/partdb
ADMIN_PASS=$(grep -oP 'The initial password for the "admin" user is: \K\w+' ~/database-migration-output)
{
  echo ""
  echo "Part-DB Admin User: admin"
  echo "Part-DB Admin Password: $ADMIN_PASS"
} >>~/partdb.creds
rm -rf ~/database-migration-output
rm -rf "/opt/v${RELEASE}.zip"
echo "${RELEASE}" >~/.partdb
msg_ok "Installed Part-DB"

msg_info "Creating Service"
cat <<EOF >/etc/apache2/sites-available/partdb.conf
<VirtualHost *:80>
    ServerName partdb
    DocumentRoot /opt/partdb/public
    <Directory /opt/partdb/public>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/partdb_error.log
    CustomLog /var/log/apache2/partdb_access.log combined
</VirtualHost>
EOF
$STD a2ensite partdb
$STD a2enmod rewrite
$STD a2dissite 000-default.conf
$STD systemctl reload apache2
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
