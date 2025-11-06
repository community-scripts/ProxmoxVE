#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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
$STD apt-get install -y nginx
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "booklore" "booklore-app/BookLore"
JAVA_VERSION="25" setup_java
NODE_VERSION="22" setup_nodejs
setup_mariadb
setup_yq

msg_info "Setting up database"
DB_NAME=booklore_db
DB_USER=booklore_user
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
$STD mariadb -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
$STD mariadb -u root -e "GRANT SELECT ON \`mysql\`.\`time_zone_name\` TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "BookLore Database Credentials"
  echo "Database: $DB_NAME"
  echo "Username: $DB_USER"
  echo "Password: $DB_PASS"
} >>~/booklore.creds
msg_ok "Set up database"

msg_info "Building Frontend"
cd /opt/booklore/booklore-ui
$STD npm install --force
$STD npm run build --configuration=production
msg_ok "Built Frontend"

msg_info "Creating Environment"
mkdir -p /opt/booklore_storage{/data,/books,/bookdrop}
cat <<EOF >/opt/booklore_storage/.env
DATABASE_URL=jdbc:mariadb://localhost:3306/$DB_NAME
DATABASE_USERNAME=$DB_USER
DATABASE_PASSWORD=$DB_PASS
BOOKLORE_PORT=6060 

BOOKLORE_DATA_PATH=/opt/booklore_storage/data
BOOKLORE_BOOKS_PATH=/opt/booklore_storage/books
BOOKLORE_BOOKDROP_PATH=/opt/booklore_storage/bookdrop
EOF
msg_ok "Created Environment"

msg_info "Building Backend"
cd /opt/booklore/booklore-api
APP_VERSION=$(curl -fsSL https://api.github.com/repos/booklore-app/BookLore/releases/latest | yq '.tag_name' | sed 's/^v//')
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

msg_info "Configure Nginx"
rm -rf /usr/share/nginx/html
ln -s /opt/booklore/booklore-ui/dist/booklore/browser /usr/share/nginx/html
cp /opt/booklore/nginx.conf /etc/nginx/nginx.conf
sed -i 's/listen \${BOOKLORE_PORT};/listen 6060;/' /etc/nginx/nginx.conf
sed -i 's/listen \[::\]:${BOOKLORE_PORT};/listen [::]:6060;/' /etc/nginx/nginx.conf
systemctl restart nginx
msg_ok "Configured Nginx"

msg_info "Creating Systemd Service"
cat <<EOF >/etc/systemd/system/booklore.service
[Unit]
Description=BookLore Java Service
After=network.target

[Service]
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
msg_ok "Created BookLore Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
