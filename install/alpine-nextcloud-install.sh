#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apk add newt
$STD apk add curl
$STD apk add openssl
$STD apk add openssh
$STD apk add nano
$STD apk add mc
$STD apk add nginx
msg_ok "Installed Dependencies"

msg_info "Installing PHP/Redis"
$STD apk add php83-opcache
$STD apk add php83-redis
$STD apk add php83-apcu
$STD apk add php83-fpm
$STD apk add php83-sysvsem
$STD apk add php83-ftp
$STD apk add php83-pecl-smbclient
$STD apk add php83-pecl-imagick
$STD apk add php83-pecl-vips
$STD apk add php83-exif
$STD apk add php83-sodium
$STD apk add php83-bz2
$STD apk add redis
msg_ok "Installed PHP/Redis"

msg_info "Installing MySQL Database"
DB_NAME=nextcloud
DB_USER=nextcloud
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
ADMIN_PASS="$(openssl rand -base64 18 | cut -c1-13)"
echo "" >>~/nextcloud.creds
echo -e "MySQL Admin Password: \e[32m$ADMIN_PASS\e[0m" >>~/nextcloud.creds
echo -e "Nextcloud Database Username: \e[32m$DB_USER\e[0m" >>~/nextcloud.creds
echo -e "Nextcloud Database Password: \e[32m$DB_PASS\e[0m" >>~/nextcloud.creds
echo -e "Nextcloud Database Name: \e[32m$DB_NAME\e[0m" >>~/nextcloud.creds
$STD apk add nextcloud-mysql mariadb mariadb-client
$STD mariadb-install-db --user=mysql --datadir=/var/lib/mysql
$STD service mariadb start
$STD rc-update add mariadb
mysql -uroot -p"$ADMIN_PASS" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '$ADMIN_PASS' WITH GRANT OPTION; DELETE FROM mysql.user WHERE User=''; DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1'); DROP DATABASE test; DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'; CREATE DATABASE $DB_NAME; GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS'; GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost.localdomain' IDENTIFIED BY '$DB_PASS'; FLUSH PRIVILEGES;"
$STD apk del mariadb-client
msg_ok "Installed MySQL Database"

msg_info "Installing Nextcloud"
ADMIN_USER=ncAdmin
echo "" >>~/nextcloud.creds
echo -e "Nextcloud Admin Username: \e[32m$ADMIN_USER\e[0m" >>~/nextcloud.creds
echo -e "Nextcloud Admin Password: \e[32m$ADMIN_PASS\e[0m (Initially enter twice)" >>~/nextcloud.creds
$STD apk add nextcloud-initscript
$STD openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/ssl/private/nextcloud-selfsigned.key -out /etc/ssl/certs/nextcloud-selfsigned.crt -subj "/C=US/O=Nextcloud/OU=Domain Control Validated/CN=nextcloud.local"
cat <<'EOF' >/usr/share/webapps/nextcloud/config/config.php
<?php
$CONFIG = array (
  'datadirectory' => '/var/lib/nextcloud/data',
  'logfile' => '/var/log/nextcloud/nextcloud.log',
  'logdateformat' => 'F d, Y H:i:s',
  'log_rotate_size' => 104857600,
  'apps_paths' => array (
    0 => array (
      'path' => '/usr/share/webapps/nextcloud/apps',
      'url' => '/apps',
      'writable' => false,
    ),
    1 => array (
      'path' => '/var/lib/nextcloud/apps',
      'url' => '/apps-appstore',
      'writable' => true,
    ),
  ),
  'updatechecker' => false,
  'check_for_working_htaccess' => false,
  'memcache.local' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => array(
    'host' => 'localhost',
    'port' => 6379,
    'dbindex' => 0,
    'timeout' => 1.5,
  ),
  'installed' => false,
);
EOF
rm -rf /etc/nginx/http.d/default.conf
cat <<'EOF' >/etc/nginx/http.d/nextcloud.conf
server {
        listen       [::]:80;
        listen       80;
        return 301 https://$host$request_uri;
        server_name localhost;
        client_max_body_size 16G;
        fastcgi_read_timeout 120s;
}
server {
        listen       443 ssl http2;
        listen       [::]:443 ssl http2;
        server_name  localhost;
        root /usr/share/webapps/nextcloud;
        index  index.php index.html index.htm;
        disable_symlinks off;
        ssl_certificate      /etc/ssl/certs/nextcloud-selfsigned.crt;
        ssl_certificate_key  /etc/ssl/private/nextcloud-selfsigned.key;
        ssl_session_timeout  5m;
        ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA;
        ssl_prefer_server_ciphers  on;
        location / {
            try_files $uri $uri/ /index.html;
        }
        location ~ [^/]\.php(/|$) {
                fastcgi_split_path_info ^(.+?\.php)(/.*)$;
                if (!-f $document_root$fastcgi_script_name) {
                        return 404;
                }
                fastcgi_pass unix:/run/nextcloud/fastcgi.sock; # From the nextcloud-initscript package
                fastcgi_index index.php;
                include fastcgi.conf;
                fastcgi_read_timeout 120s;
                client_max_body_size 16G;
        }
        location ^~ /.well-known/carddav { return 301 /remote.php/dav/; }
        location ^~ /.well-known/caldav { return 301 /remote.php/dav/; }
        location ^~ /.well-known/webfinger { return 301 /index.php/.well-known/webfinger; }
        location ^~ /.well-known/nodeinfo { return 301 /index.php/.well-known/nodeinfo; }
}
EOF
sed -i -e 's|memory_limit = 128M|memory_limit = 512M|; $aapc.enable_cli=1' /etc/php83/php.ini
sed -i -e 's|upload_max_file_size = 2M|upload_max_file_size = 16G|' /etc/php83/php.ini 
sed -i -E '/^php_admin_(flag|value)\[opcache/s/^/;/' /etc/php83/php-fpm.d/nextcloud.conf
msg_ok "Installed Nextcloud"

msg_info "Adding Additional Nextcloud Packages"
$STD apk add nextcloud-occ
$STD apk add nextcloud-default-apps
$STD apk add nextcloud-activity
$STD apk add nextcloud-admin_audit
$STD apk add nextcloud-comments
$STD apk add nextcloud-dashboard
$STD apk add nextcloud-doc
$STD apk add nextcloud-encryption
$STD apk add nextcloud-federation
$STD apk add nextcloud-files_external
$STD apk add nextcloud-files_sharing
$STD apk add nextcloud-files_trashbin
$STD apk add nextcloud-files_versions
$STD apk add nextcloud-notifications
$STD apk add nextcloud-sharebymail
$STD apk add nextcloud-suspicious_login
$STD apk add nextcloud-support
$STD apk add nextcloud-systemtags
$STD apk add nextcloud-user_status
$STD apk add nextcloud-weather_status
msg_ok "Added Additional Nextcloud Packages"

msg_info "Starting Services"
$STD rc-service redis start
$STD rc-update add redis default
$STD rc-service php-fpm83 start
chown -R nextcloud:www-data /var/log/nextcloud/
chown -R nextcloud:www-data /usr/share/webapps/nextcloud/
$STD rc-service php-fpm83 restart
$STD rc-service nginx start
$STD rc-service nextcloud start
$STD rc-update add nginx default
$STD rc-update add nextcloud default
msg_ok "Started Services"

msg_info "Start Nextcloud Setup-Wizard"
echo -e "export VISUAL=nano\nexport EDITOR=nano" >>/etc/profile
cd /usr/share/webapps/nextcloud
$STD su nextcloud -s /bin/sh -c "php83 occ maintenance:install \
--database='mysql' --database-name $DB_NAME \
--database-user '$DB_USER' --database-pass '$DB_PASS' \
--admin-user '$ADMIN_USER' --admin-pass '$ADMIN_PASS' \
--data-dir '/var/lib/nextcloud/data'"
$STD su nextcloud -s /bin/sh -c 'php83 occ background:cron'
rm -rf /usr/share/webapps/nextcloud/apps/serverinfo
IP4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
sed -i "/0 => \'localhost\',/a \    \1 => '$IP4'," /usr/share/webapps/nextcloud/config/config.php
su nextcloud -s /bin/sh -c 'php83 -f /usr/share/webapps/nextcloud/cron.php'
msg_ok "Finished Nextcloud Setup-Wizard"

motd_ssh
customize
