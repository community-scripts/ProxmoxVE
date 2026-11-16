#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Masked-Kunsiquat
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.espocrm.com/ | Github: https://github.com/espocrm/espocrm

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

if [[ -z "${var_admin_user:-}" ]]; then
  var_admin_user=$(prompt_input "EspoCRM admin username (a-z, 0-9, @ . _ -):" "admin" 60)
fi
var_admin_user="${var_admin_user:-admin}"
var_admin_user="${var_admin_user,,}"
if [[ ! "$var_admin_user" =~ ^[a-z0-9@._-]+$ ]]; then
  msg_warn "EspoCRM usernames take only a-z, 0-9 and @ . _ -; using admin"
  var_admin_user="admin"
fi
if [[ -z "${var_admin_pass:-}" ]]; then
  var_admin_pass=$(random_password 16)
fi

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

setup_mariadb
MARIADB_DB_NAME="espocrm" MARIADB_DB_USER="espocrm" setup_mariadb_db
PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="ldap" setup_php
fetch_and_deploy_gh_release "espo-crm" "espocrm/espocrm" "prebuild" "latest" "/opt/espocrm" "EspoCRM-*.zip"

msg_info "Configuring EspoCRM"
cd /opt/espocrm
$STD php bin/command config:populate
$STD php bin/command config:set defaultPermissions.user www-data
$STD php bin/command config:set defaultPermissions.group www-data
$STD php bin/command config:set database.platform Mysql
$STD php bin/command config:set database.host localhost
$STD php bin/command config:set database.dbname "$MARIADB_DB_NAME"
$STD php bin/command config:set database.user "$MARIADB_DB_USER"
$STD php bin/command config:set database.password "$MARIADB_DB_PASS"
$STD php bin/command rebuild
$STD php bin/command create-admin-user "$var_admin_user"
printf '%s\n' "$var_admin_pass" | $STD php bin/command set-password "$var_admin_user"
$STD php bin/command config:set siteUrl "http://${LOCAL_IP}"
$STD php bin/command populate-scheduled-jobs
$STD php bin/command config:set jobRunInParallel true --type=bool
$STD php bin/command app-check
$STD php bin/command config:set isInstalled true --type=bool
chown -R www-data:www-data /opt/espocrm
msg_ok "Configured EspoCRM"

msg_info "Creating Nginx Site"
PHP_SOCK=$(get_php_fpm_socket)
cat <<EOF >/etc/nginx/sites-available/espocrm
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    charset utf-8;
    index index.html index.php;

    client_max_body_size 128M;
    keepalive_timeout 300;
    server_tokens off;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;

    gzip on;
    gzip_types text/plain text/css text/javascript application/javascript application/json;
    gzip_min_length 1000;

    root /opt/espocrm/public;

    location /client {
        root /opt/espocrm;
        autoindex off;

        location ~* ^.+\.(js|css|png|jpg|svg|svgz|jpeg|gif|ico|tpl)\$ {
            access_log off;
            expires max;
        }
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt { access_log off; log_not_found off; }

    location ~ \.php\$ {
        fastcgi_pass unix:${PHP_SOCK};
        include fastcgi_params;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param QUERY_STRING \$query_string;
    }

    location /api/v1/ {
        if (!-e \$request_filename) {
            rewrite ^/api/v1/(.*)\$ /api/v1/index.php last;
        }
    }

    location /portal/ {
        try_files \$uri \$uri/ /portal/index.php?\$query_string;
    }

    location /api/v1/portal-access {
        if (!-e \$request_filename) {
            rewrite ^/api/v1/(.*)\$ /api/v1/portal-access/index.php last;
        }
    }

    location ~ /(\.htaccess|web\.config|\.git) {
        deny all;
    }
}
EOF
msg_ok "Created Nginx Site"
nginx_enable_site "espocrm"

msg_info "Setting up Cron"
cat <<EOF >/etc/cron.d/espocrm
* * * * * www-data cd /opt/espocrm && php -f cron.php >/dev/null 2>&1
EOF
systemctl enable -q --now cron
msg_ok "Set up Cron"

msg_info "Saving Credentials"
cat <<EOF >>~/espocrm.creds

EspoCRM Admin
Username: ${var_admin_user}
Password: ${var_admin_pass}
EOF
chmod 600 ~/espocrm.creds
msg_ok "Saved Credentials"

motd_ssh
customize
cleanup_lxc
