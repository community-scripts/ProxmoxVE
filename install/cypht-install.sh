#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cypht-org/cypht

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

PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="soap,ldap" setup_php
fetch_and_deploy_gh_release "cypht" "cypht-org/cypht" "prebuild" "latest" "/opt/cypht" "cypht.tar.gz"

msg_info "Configuring Cypht"
var_admin_user="${var_admin_user:-admin}"
var_admin_pass="${var_admin_pass:-$(random_password)}"
mkdir -p /opt/cypht_data/{users,attachments}
cp /opt/cypht/.env /opt/cypht_data/.env
sed -i \
  -e 's|^DB_DRIVER=.*|DB_DRIVER=sqlite|' \
  -e 's|^DB_NAME=.*|DB_NAME=/opt/cypht_data/users/cypht.db|' \
  -e 's|^SESSION_TYPE=.*|SESSION_TYPE=DB|' \
  -e 's|^AUTH_TYPE=.*|AUTH_TYPE=DB|' \
  -e 's|^USER_CONFIG_TYPE=.*|USER_CONFIG_TYPE=DB|' \
  -e 's|^USER_SETTINGS_DIR=.*|USER_SETTINGS_DIR=/opt/cypht_data/users|' \
  -e 's|^ATTACHMENT_DIR=.*|ATTACHMENT_DIR=/opt/cypht_data/attachments|' \
  -e "s|^ADMIN_USERS=.*|ADMIN_USERS=${var_admin_user}|" \
  -e 's|^ENABLE_REDIS=.*|ENABLE_REDIS=false|' \
  -e 's|^ENABLE_MEMCACHED=.*|ENABLE_MEMCACHED=false|' \
  /opt/cypht_data/.env
cat <<EOF >>/opt/cypht_data/.env

CYPHT_ADMIN_USER='${var_admin_user}'
CYPHT_ADMIN_PASS='${var_admin_pass}'
EOF
ln -sf /opt/cypht_data/.env /opt/cypht/.env
cd /opt/cypht
$STD php scripts/setup_database.php
$STD php scripts/create_account.php "$var_admin_user" "$var_admin_pass"
$STD php scripts/config_gen.php
chown -R www-data:www-data /opt/cypht_data/users /opt/cypht_data/attachments
chown root:www-data /opt/cypht_data/.env
chmod 640 /opt/cypht_data/.env
msg_ok "Configured Cypht"

msg_info "Configuring Nginx"
PHP_SOCK=$(get_php_fpm_socket)
cat <<EOF >/etc/nginx/sites-available/cypht
server {
    listen 80;
    server_name _;

    root /opt/cypht/site;
    index index.php;
    client_max_body_size 60M;

    location / {
        try_files \$uri /index.php\$is_args\$args;
    }
    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_index index.php;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
EOF
nginx_enable_site "cypht"
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
