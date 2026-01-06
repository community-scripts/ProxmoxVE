#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://plant-it.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
    redis \
    nginx
msg_ok "Installed Dependencies"

setup_mariadb
MARIADB_DB_NAME="plantit" MARIADB_DB_USER="plantit_usr" setup_mariadb_db
JAVA_VERSION="21" setup_java
USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "plant-it" "MDeLuise/plant-it" "singlefile" "0.10.0" "/opt/plant-it/backend" "server.jar"
fetch_and_deploy_gh_release "plant-it-front" "MDeLuise/plant-it" "prebuild" "0.10.0" "/opt/plant-it/frontend" "client.tar.gz"

msg_info "Configured Plant-it"
mkdir -p /opt/plant-it-data
cat <<EOF >/opt/plant-it/backend/server.env
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USERNAME=$MARIADB_DB_USER
MYSQL_PSW=$MARIADB_DB_PASS
MYSQL_DATABASE=$MARIADB_DB_NAME
MYSQL_ROOT_PASSWORD=$MARIADB_DB_PASS

JWT_SECRET=$JWT_SECRET
JWT_EXP=1

USERS_LIMIT=-1
UPLOAD_DIR=/opt/plant-it-data
API_PORT=8080
FLORACODEX_KEY=
LOG_LEVEL=DEBUG
ALLOWED_ORIGINS=*

CACHE_TYPE=redis
CACHE_TTL=86400
CACHE_HOST=localhost
CACHE_PORT=6379
EOF
msg_ok "Configured Plant-it"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/plant-it.service
[Unit]
Description=Plant-it Backend Service
After=syslog.target network.target

[Service]
Type=simple
WorkingDirectory=/opt/plant-it/backend
EnvironmentFile=/opt/plant-it/backend/server.env
ExecStart=/usr/bin/java -jar -Xmx2g server.jar
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now plant-it

cat <<EOF >/etc/nginx/nginx.conf
events {
    worker_connections 1024;
}

http {
    server {
        listen 3000;
        server_name localhost;

        root /opt/plant-it/frontend;
        index index.html;

        location / {
            try_files \$uri \$uri/ /index.html;
        }

        error_page 404 /404.html;
        location = /404.html {
            internal;
        }
    }
}
EOF
systemctl restart nginx
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
