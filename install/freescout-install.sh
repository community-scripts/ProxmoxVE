#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/freescout-help-desk/freescout

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

var_admin_email="${var_admin_email:-admin@example.com}"
if [[ ! "$var_admin_email" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]]; then
  msg_warn "Invalid admin email '${var_admin_email}', using admin@example.com"
  var_admin_email="admin@example.com"
fi
var_admin_pass="${var_admin_pass:-$(random_password 16)}"

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

setup_mariadb
MARIADB_DB_NAME="freescout" MARIADB_DB_USER="freescout" setup_mariadb_db
PHP_VERSION="8.4" PHP_FPM="YES" setup_php
fetch_and_deploy_gh_release "freescout" "freescout-help-desk/freescout" "tarball"

msg_info "Configuring FreeScout"
cd /opt/freescout
cat <<EOF >/opt/freescout/.env
APP_URL=http://${LOCAL_IP}
DB_CONNECTION=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=freescout
DB_USERNAME=freescout
DB_PASSWORD=${MARIADB_DB_PASS}
APP_KEY=
EOF
$STD php artisan key:generate --force
$STD php artisan storage:link
$STD php artisan migrate --force
$STD php artisan freescout:create-user --role=admin --firstName=Admin --lastName=FreeScout --email="$var_admin_email" --password="$var_admin_pass" --no-interaction
touch /opt/freescout/storage/.installed
$STD php artisan freescout:clear-cache
chown -R www-data:www-data /opt/freescout
cat <<EOF >>~/freescout.creds

FreeScout Admin
Email: ${var_admin_email}
Password: ${var_admin_pass}
EOF
chmod 600 ~/freescout.creds
msg_ok "Configured FreeScout"

msg_info "Configuring Nginx"
sed -i 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/8.4/fpm/php.ini
systemctl restart php8.4-fpm
PHP_SOCK=$(get_php_fpm_socket)
cat <<EOF >/etc/nginx/sites-available/freescout
server {
    listen 80;
    listen [::]:80;
    server_name _;

    root /opt/freescout/public;
    index index.php index.html index.htm;

    client_max_body_size 128M;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    location ~* ^/storage/attachment/ {
        expires 1M;
        access_log off;
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~* ^/(?:css|js)/.*\.(?:css|js)\$ {
        expires 2d;
        access_log off;
        add_header Cache-Control "public, must-revalidate";
        add_header X-Content-Type-Options "nosniff";
    }
    location ~* ^/storage/.*\.((?!(jpg|jpeg|jfif|pjpeg|pjp|apng|bmp|gif|ico|cur|png|tif|tiff|webp|pdf|txt|diff|patch|json|mp3|wav|ogg|wma)).)*\$ {
        add_header Content-disposition "attachment; filename=\$2";
        add_header X-Content-Type-Options "nosniff";
        default_type application/octet-stream;
    }
    location ~* ^/(storage/|.*\.).*\$ {
        expires 1M;
        access_log off;
        add_header Cache-Control "public";
        add_header X-Content-Type-Options "nosniff";
    }
    location ~ /\. {
        deny all;
    }
}
EOF
nginx_enable_site "freescout"
msg_ok "Configured Nginx"

msg_info "Setting up Cron"
cat <<EOF >/etc/cron.d/freescout
* * * * * www-data php /opt/freescout/artisan schedule:run >/dev/null 2>&1
EOF
systemctl enable -q --now cron
msg_ok "Set up Cron"

motd_ssh
customize
cleanup_lxc
