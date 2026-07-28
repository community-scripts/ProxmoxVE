#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/timothepoznanski/poznote

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

PHP_VERSION="8.4" PHP_FPM="YES" setup_php

fetch_and_deploy_gh_release "poznote" "timothepoznanski/poznote" "tarball"

msg_info "Deploying Poznote"
mkdir -p /var/www/html/data/database
cp -r /opt/poznote/src/. /var/www/html/
touch /var/www/html/data/database/poznote.db
chown -R www-data:www-data /var/www/html
msg_ok "Deployed Poznote"

msg_info "Configuring Nginx"
PHP_SOCK=$(get_php_fpm_socket)
cat <<EOF >/etc/nginx/sites-available/poznote
server {
    listen 8040;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$document_root;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
nginx_enable_site poznote
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
