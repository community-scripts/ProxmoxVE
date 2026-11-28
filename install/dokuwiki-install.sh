#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dokuwiki/dokuwiki

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

var_admin_user="${var_admin_user:-admin}"
var_admin_user="${var_admin_user,,}"
if [[ ! "$var_admin_user" =~ ^[a-z0-9._-]+$ ]]; then
  msg_warn "Invalid admin username '${var_admin_user}', using admin"
  var_admin_user="admin"
fi
var_admin_pass="${var_admin_pass:-$(random_password 16)}"

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

PHP_VERSION="8.4" PHP_FPM="YES" setup_php
fetch_and_deploy_gh_release "dokuwiki" "dokuwiki/dokuwiki" "prebuild" "latest" "/opt/dokuwiki" "dokuwiki-*.tgz"

msg_info "Configuring DokuWiki"
mkdir -p /opt/dokuwiki_data
cat <<EOF >/opt/dokuwiki_data/.env
DOKUWIKI_ADMIN_USER=${var_admin_user}
DOKUWIKI_ADMIN_PASS=${var_admin_pass}
EOF
chmod 600 /opt/dokuwiki_data/.env
cat <<'EOF' >/opt/dokuwiki/conf/local.php
<?php
$conf['title'] = 'DokuWiki';
$conf['lang'] = 'en';
$conf['license'] = 'cc-by-sa';
$conf['useacl'] = 1;
$conf['superuser'] = '@admin';
$conf['disableactions'] = 'register';
$conf['userewrite'] = 1;
EOF
ADMIN_HASH=$(php -r 'echo password_hash($argv[1], PASSWORD_BCRYPT);' "$var_admin_pass")
cat <<EOF >/opt/dokuwiki/conf/users.auth.php
# users.auth.php
# <?php exit()?>
# Don't modify the lines above
#
# login:passwordhash:Real Name:email:groups,comma,separated

${var_admin_user}:${ADMIN_HASH}:Administrator:admin@localhost:admin,user
EOF
cat <<'EOF' >/opt/dokuwiki/conf/acl.auth.php
# acl.auth.php
# <?php exit()?>
# Don't modify the lines above
#
# none 0, read 1, edit 2, create 4, upload 8, delete 16

*               @ALL          1
*               @user         8
EOF
cat <<'EOF' >/opt/dokuwiki/conf/plugins.local.php
<?php
$plugins['authad'] = 0;
$plugins['authldap'] = 0;
EOF
rm -f /opt/dokuwiki/install.php
chown -R www-data:www-data /opt/dokuwiki
msg_ok "Configured DokuWiki"

msg_info "Configuring Nginx"
PHP_SOCK=$(get_php_fpm_socket)
cat <<EOF >/etc/nginx/sites-available/dokuwiki
server {
    listen 80;
    listen [::]:80;
    server_name _;

    root /opt/dokuwiki;
    index doku.php;

    client_max_body_size 128M;
    server_tokens off;
    fastcgi_hide_header X-Powered-By;

    location ~ ^/(conf|bin|inc|vendor)/ {
        deny all;
    }
    location ~ ^/data/ {
        internal;
    }
    location ~ /\.|^/(install\.php|README|VERSION|COPYING|SECURITY\.md)\$ {
        deny all;
    }
    location ~ ^/lib.*\.(js|css|gif|png|ico|jpg|jpeg|svg)\$ {
        expires 365d;
    }
    location / {
        try_files \$uri \$uri/ @dokuwiki;
    }
    location @dokuwiki {
        rewrite ^/_media/(.*) /lib/exe/fetch.php?media=\$1 last;
        rewrite ^/_detail/(.*) /lib/exe/detail.php?media=\$1 last;
        rewrite ^/_export/([^/]+)/(.*) /doku.php?do=export_\$1&id=\$2 last;
        rewrite ^/(.*) /doku.php?id=\$1&\$args last;
    }
    location ~ \.php\$ {
        try_files \$uri \$uri/ /doku.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param REDIRECT_STATUS 200;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
EOF
nginx_enable_site "dokuwiki"
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
