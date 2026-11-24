#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/typecho/typecho

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
  sqlite3
msg_ok "Installed Dependencies"

PHP_FPM="YES" setup_php
fetch_and_deploy_gh_release "typecho" "typecho/typecho" "prebuild" "latest" "/opt/typecho" "typecho.zip"
fetch_and_deploy_from_url "https://github.com/typecho/languages/releases/download/ci/langs.zip" "/opt/typecho/usr/langs"

var_admin_user="${var_admin_user:-admin}"
var_admin_pass="${var_admin_pass:-$(random_password 16)}"

msg_info "Installing Typecho"
mkdir -p /opt/typecho_data
mv /opt/typecho/usr /opt/typecho_data/usr
ln -s /opt/typecho_data/usr /opt/typecho/usr
cd /opt/typecho
TYPECHO_SITE_URL="http://${LOCAL_IP}" \
  TYPECHO_LANG="en_US" \
  TYPECHO_DB_ADAPTER="Pdo_SQLite" \
  TYPECHO_DB_FILE="/opt/typecho_data/typecho.db" \
  TYPECHO_USER_NAME="${var_admin_user}" \
  TYPECHO_USER_PASSWORD="${var_admin_pass}" \
  $STD php install.php
# PHP resolves symlinks in __FILE__, so a linked config has to name the root itself
sed -i "s|dirname(__FILE__)|'/opt/typecho'|" config.inc.php
mv config.inc.php /opt/typecho_data/config.inc.php
ln -s /opt/typecho_data/config.inc.php /opt/typecho/config.inc.php
rm -f install.php
# upstream defaults to UTC+8 and index.php URLs; the vhost below handles rewritten ones
sqlite3 /opt/typecho_data/typecho.db "UPDATE typecho_options SET value = '1' WHERE name = 'rewrite'; UPDATE typecho_options SET value = '0' WHERE name = 'timezone';"
chown -R www-data:www-data /opt/typecho_data
cat <<EOF >~/typecho.creds
Typecho Admin
URL: http://${LOCAL_IP}/admin/
Username: ${var_admin_user}
Password: ${var_admin_pass}
EOF
chmod 600 ~/typecho.creds
msg_ok "Installed Typecho"

msg_info "Configuring Nginx"
PHP_SOCK=$(get_php_fpm_socket)
cat <<EOF >/etc/nginx/sites-available/typecho
server {
    listen 80 default_server;
    server_name _;
    root /opt/typecho;
    index index.php;
    client_max_body_size 128M;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    location ~ [^/]\.php(/|\$) {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
EOF
nginx_enable_site "typecho"
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
