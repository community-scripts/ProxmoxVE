#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://privatebin.info/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  nginx \
  openssl
msg_ok "Installed Dependencies"

PHP_VERSION="8.2" PHP_MODULE="common,fpm" setup_php
fetch_and_deploy_gh_release "privatebin" "PrivateBin/PrivateBin" "tarball"

msg_info "Generating Universal SSL Certificate"
mkdir -p /etc/ssl/privatebin
$STD openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /etc/ssl/privatebin/key.pem \
  -out /etc/ssl/privatebin/cert.pem \
  -subj "/CN=PrivateBin"
msg_ok "Certificate Generated"

msg_info "Configuring Environment"
mkdir -p /opt/privatebin/data
cp /opt/privatebin/cfg/conf.sample.php /opt/privatebin/cfg/conf.php
sed -i "s|// 'traffic'|'traffic'|g" /opt/privatebin/cfg/conf.php
chown -R www-data:www-data /opt/privatebin
chmod -R 0755 /opt/privatebin/data
msg_ok "Configured Environment"

msg_info "Configuring PHP"
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/8.2/fpm/php.ini
systemctl restart php8.2-fpm
msg_ok "Configured PHP"

msg_info "Configuring Universal Nginx"
cat <<EOF >/etc/nginx/sites-available/privatebin.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    
    ssl_certificate /etc/ssl/privatebin/cert.pem;
    ssl_certificate_key /etc/ssl/privatebin/key.pem;
    
    root /opt/privatebin;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
}
EOF
ln -s /etc/nginx/sites-available/privatebin.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx
msg_ok "Nginx Configured"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
