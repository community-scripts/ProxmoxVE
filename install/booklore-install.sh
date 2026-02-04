#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/booklore-app/BookLore

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

JAVA_VERSION="21" setup_java
NODE_VERSION="22" setup_nodejs
setup_mariadb
setup_yq
MARIADB_DB_NAME="booklore_db" MARIADB_DB_USER="booklore_user" MARIADB_DB_EXTRA_GRANTS="GRANT SELECT ON \`mysql\`.\`time_zone_name\`" setup_mariadb_db
fetch_and_deploy_gh_release "booklore" "booklore-app/BookLore" "tarball"

msg_info "Building Frontend"
cd /opt/booklore/booklore-ui
$STD npm install --force
$STD npm run build --configuration=production
msg_ok "Built Frontend"

msg_info "Creating Environment"
mkdir -p /opt/booklore_storage/{data,books,bookdrop}
cat <<EOF >/opt/booklore_storage/.env
# Database Configuration
DATABASE_URL=jdbc:mariadb://localhost:3306/${MARIADB_DB_NAME}
DATABASE_USERNAME=${MARIADB_DB_USER}
DATABASE_PASSWORD=${MARIADB_DB_PASS}

# App Configuration (Spring Boot mapping from app.* properties)
APP_PATH_CONFIG=/opt/booklore_storage/data
APP_BOOKDROP_FOLDER=/opt/booklore_storage/bookdrop
EOF
msg_ok "Created Environment"

msg_info "Building Backend"
cd /opt/booklore/booklore-api
APP_VERSION=$(get_latest_github_release "booklore-app/BookLore")
yq eval ".app.version = \"${APP_VERSION}\"" -i src/main/resources/application.yaml
$STD ./gradlew clean build --no-daemon
mkdir -p /opt/booklore/dist
JAR_PATH=$(find /opt/booklore/booklore-api/build/libs -maxdepth 1 -type f -name "booklore-api-*.jar" ! -name "*plain*" | head -n1)
if [[ -z "$JAR_PATH" ]]; then
  msg_error "Backend JAR not found"
  exit 1
fi
cp "$JAR_PATH" /opt/booklore/dist/app.jar
msg_ok "Built Backend"

msg_info "Configuring Nginx"
rm -rf /usr/share/nginx/html
ln -s /opt/booklore/booklore-ui/dist/booklore/browser /usr/share/nginx/html
rm -f /etc/nginx/sites-enabled/default
cp /opt/booklore/nginx.conf /etc/nginx/nginx.conf
sed -i 's/listen \${BOOKLORE_PORT};/listen 6060;/' /etc/nginx/nginx.conf
sed -i 's/listen \[::\]:${BOOKLORE_PORT};/listen [::]:6060;/' /etc/nginx/nginx.conf
systemctl restart nginx
msg_ok "Configured Nginx"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/booklore.service
[Unit]
Description=BookLore Java Service
After=network.target mariadb.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/booklore/dist
ExecStart=/usr/bin/java -jar /opt/booklore/dist/app.jar
EnvironmentFile=/opt/booklore_storage/.env
SuccessExitStatus=143
TimeoutStopSec=10
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now booklore
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
