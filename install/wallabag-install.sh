#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wallabag.org/

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
  redis-server \
  imagemagick
msg_ok "Installed Dependencies"

setup_mariadb
MARIADB_DB_NAME="wallabag" MARIADB_DB_USER="wallabag" setup_mariadb_db
PHP_VERSION="8.3" PHP_FPM="YES" PHP_MODULE="tidy" setup_php
setup_composer
NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "wallabag" "wallabag/wallabag" "prebuild" "latest" "/opt/wallabag" "wallabag-*.tar.gz"

msg_info "Configuring Wallabag"
cd /opt/wallabag
SECRET_KEY="$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)"
cat <<EOF >/opt/wallabag/app/config/parameters.yml
parameters:
    database_driver: pdo_mysql
    database_host: 127.0.0.1
    database_port: 3306
    database_name: ${MARIADB_DB_NAME}
    database_user: ${MARIADB_DB_USER}
    database_password: ${MARIADB_DB_PASS}
    database_path: null
    database_table_prefix: wallabag_
    database_socket: null
    database_charset: utf8mb4

    domain_name: http://${LOCAL_IP}:8000
    server_name: Wallabag

    mailer_dsn: null

    locale: en

    secret: ${SECRET_KEY}

    twofactor_auth: false
    twofactor_sender: no-reply@wallabag.org

    fosuser_registration: true
    fosuser_confirmation: false

    fos_oauth_server_access_token_lifetime: 3600
    fos_oauth_server_refresh_token_lifetime: 1209600

    from_email: no-reply@wallabag.org

    rss_limit: 50

    rabbitmq_host: localhost
    rabbitmq_port: 5672
    rabbitmq_user: guest
    rabbitmq_password: guest
    rabbitmq_prefetch_count: 10

    redis_scheme: tcp
    redis_host: localhost
    redis_port: 6379
    redis_path: null
    redis_password: null

    sentry_dsn: null
EOF
chown -R www-data:www-data /opt/wallabag
msg_ok "Configured Wallabag"

msg_info "Installing Wallabag (Patience)"
export COMPOSER_ALLOW_SUPERUSER=1
export SYMFONY_ENV=prod
cd /opt/wallabag
$STD php bin/console wallabag:install --env=prod --no-interaction
$STD php bin/console cache:clear --env=prod
chown -R www-data:www-data /opt/wallabag
chmod -R 755 /opt/wallabag/{var,web/assets}
msg_ok "Installed Wallabag"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/wallabag
server {
    listen 8000;
    server_name _;
    root /opt/wallabag/web;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index app.php;
    charset utf-8;

    location / {
        try_files $uri /app.php$is_args$args;
    }

    location ~ ^/app\.php(/|$) {
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $realpath_root;
        internal;
    }

    location ~ \.php$ {
        return 404;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    error_log /var/log/nginx/wallabag_error.log;
    access_log /var/log/nginx/wallabag_access.log;
}
EOF

ln -sf /etc/nginx/sites-available/wallabag /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
$STD systemctl reload nginx
msg_ok "Configured Nginx"

msg_info "Enabling Services"
systemctl enable -q --now redis-server
systemctl enable -q --now php8.3-fpm
systemctl enable -q --now nginx
msg_ok "Enabled Services"

motd_ssh
customize
cleanup_lxc
