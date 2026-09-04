#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/timothepoznanski/poznote

APP="Poznote"
var_tags="${var_tags:-notes;documentation;php}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /var/www/html/data ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "poznote" "timothepoznanski/poznote"; then
    msg_info "Stopping Service"
    systemctl stop nginx
    systemctl stop poznote-reminder-worker poznote-s3-backup-worker 2>/dev/null || true
    msg_ok "Stopped Service"

    create_backup /var/www/html/data

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "poznote" "timothepoznanski/poznote" "tarball"

    msg_info "Deploying New Version"
    cp -r /opt/poznote/src/. /var/www/html/
    chown -R www-data:www-data /var/www/html
    msg_ok "Deployed New Version"

    restore_backup

    msg_info "Running Poznote Initialization"
    chmod +x /opt/poznote/init.sh
    $STD /opt/poznote/init.sh
    msg_ok "Initialized Poznote Data Directory"

    msg_info "Updating Nginx Configuration"
    [[ -f /etc/nginx/sites-available/poznote ]] && cp /etc/nginx/sites-available/poznote /etc/nginx/sites-available/poznote.bak
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
    msg_ok "Updated Nginx Configuration"

    if [[ ! -f /etc/systemd/system/poznote-reminder-worker.service ]]; then
      msg_info "Creating Reminder Worker Service"
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
      systemctl daemon-reload
      msg_ok "Created Reminder Worker Service"
    fi

    if [[ ! -f /etc/systemd/system/poznote-s3-backup-worker.service ]]; then
      msg_info "Creating S3 Backup Worker Service"
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
      systemctl daemon-reload
      msg_ok "Created S3 Backup Worker Service"
    fi

    msg_info "Starting Service"
    systemctl start nginx
    systemctl enable -q --now poznote-reminder-worker poznote-s3-backup-worker
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8040${CL}"
