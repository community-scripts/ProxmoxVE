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

msg_info "Running Poznote Initialization"
chmod +x /opt/poznote/init.sh
$STD /opt/poznote/init.sh
msg_ok "Initialized Poznote Data Directory"

msg_info "Configuring Nginx"
PHP_SOCK=$(get_php_fpm_socket)
cat <<EOF >/etc/nginx/sites-available/poznote
# The Excalidraw editor must keep its window.opener relationship with
# libraries.excalidraw.com so "Add to Excalidraw" can hand the chosen library
# back to the already-open editor tab; COOP same-origin would sever it.
map \$uri \$poznote_coop {
    default                  "same-origin";
    /excalidraw_editor.php   "unsafe-none";
}

server {
    listen 8040;
    root /var/www/html;
    index index.php index.html;

    gzip on;
    gzip_comp_level 5;
    gzip_min_length 1024;
    gzip_vary on;
    gzip_proxied any;
    gzip_types text/css application/javascript text/javascript application/json
               image/svg+xml application/manifest+json font/ttf font/otf;

    location ~* \.webmanifest$ {
        default_type application/manifest+json;
        try_files \$uri =404;
    }

    client_max_body_size 800M;

    location /api/v1 {
        try_files \$uri \$uri/ /api/v1/index.php?\$query_string;
    }

    location = /api/health {
        rewrite ^ /api_health.php last;
    }

    location = /api/info {
        rewrite ^ /api_health.php last;
    }

    location / {
        try_files \$uri \$uri/ @poznote_public;
    }

    location @poznote_public {
        rewrite ^/folder/([^/]+)/?$ /public_folder.php?token=\$1 last;
        rewrite ^/workspace/([^/]+)/?$ /public_note.php?token=\$1 last;
        rewrite ^/([^/]+)/?$ /public_slug.php?slug=\$1 last;
    }

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Cross-Origin-Opener-Policy \$poznote_coop always;
    add_header Cross-Origin-Resource-Policy "same-origin" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=()" always;

    location ~* ^/data/.*\.(php[0-9]?|phtml|phar|pht)$ {
        deny all;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$document_root;
        fastcgi_param PATH_INFO \$fastcgi_path_info;

        fastcgi_param HTTP_X_FORWARDED_FOR \$http_x_forwarded_for;
        fastcgi_param HTTP_X_FORWARDED_PROTO \$http_x_forwarded_proto;
        fastcgi_param HTTP_X_FORWARDED_HOST \$http_x_forwarded_host;
        fastcgi_param HTTP_X_FORWARDED_PORT \$http_x_forwarded_port;
        fastcgi_param HTTP_X_REAL_IP \$http_x_real_ip;
        fastcgi_param HTTPS \$https if_not_empty;

        # fastcgi_read_timeout 600;
        # fastcgi_send_timeout 600;
        # Left at nginx's 60s default, not Docker's 600s:
        # a stalled git-sync request can hold the PHP session lock, otherwise
    }

    location ~ /\. {
        deny all;
    }

    location ~ ^/data/users/[0-9]+/backgrounds/ {
        try_files \$uri =404;
    }

    location ~ ^/data/css/[A-Za-z0-9._-]+\.css$ {
        try_files \$uri =404;
    }

    location ~ ^/(data|config)/ {
        deny all;
    }

    location ~* ^/pwa/poznote(-[0-9]+)?\.png$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options "nosniff" always;
        add_header Cross-Origin-Resource-Policy "cross-origin" always;
        try_files \$uri =404;
    }

    location ~* \.(?:js|css|png|jpg|jpeg|gif|svg|ico|woff2?|ttf|otf|eot|webp|webmanifest)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options "nosniff" always;
        add_header Cross-Origin-Resource-Policy "same-origin" always;
        try_files \$uri =404;
    }
}
EOF
nginx_enable_site poznote
msg_ok "Configured Nginx"

msg_info "Creating Background Worker Services"
cat <<EOF >/etc/systemd/system/poznote-reminder-worker.service
[Unit]
Description=Poznote Reminder Email Worker
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/html/workers/reminder-email-worker.php
WorkingDirectory=/var/www/html

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/poznote-s3-backup-worker.service
[Unit]
Description=Poznote S3 Backup Worker
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/html/workers/s3-backup-worker.php
WorkingDirectory=/var/www/html

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now poznote-reminder-worker poznote-s3-backup-worker
msg_ok "Created Background Worker Services"

motd_ssh
customize
cleanup_lxc
