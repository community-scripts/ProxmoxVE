#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tteck (tteckster) | Co-Author: Slaviša Arežina (tremor021), remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/keycloak/keycloak

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

JAVA_VERSION=21 setup_java
PG_VERSION=16 setup_postgresql

msg_info "Configuring PostgreSQL"
DB_NAME="keycloak"
DB_USER="keycloak"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8';"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
msg_ok "Configured PostgreSQL"

fetch_and_deploy_gh_release "keycloak_app" "keycloak/keycloak" "prebuild" "latest" "/opt/keycloak" "keycloak-*.tar.gz"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/keycloak.service
[Unit]
Description=Keycloak Service
Requires=network.target
After=syslog.target network-online.target

[Service]
Type=idle
User=root
WorkingDirectory=/opt/keycloak
ExecStart=/opt/keycloak/bin/kc.sh start
ExecStop=/opt/keycloak/bin/kc.sh stop
Restart=always
RestartSec=3
Environment="JAVA_HOME=/usr/lib/jvm/temurin-21-jdk-amd64"
Environment="KC_DB=postgres"
Environment="KC_DB_USERNAME=$DB_USER"
Environment="KC_DB_PASSWORD=$DB_PASS"
Environment="KC_HTTP_ENABLED=true"
Environment="KC_BOOTSTRAP_ADMIN_USERNAME=tmpadm"
Environment="KC_BOOTSTRAP_ADMIN_PASSWORD=admin123"
# Comment following line and uncomment the next 2 if working behind a reverse proxy
Environment="KC_HOSTNAME_STRICT=false"
#Environment="KC_HOSTNAME=keycloak.example.com"
#Environment="KC_PROXY_HEADERS=xforwarded"
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now keycloak
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
