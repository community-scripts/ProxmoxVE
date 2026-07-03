#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/tolgee/tolgee-platform

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

JAVA_VERSION="21" setup_java
PG_VERSION="16" setup_postgresql
PG_DB_NAME="tolgee" PG_DB_USER="tolgee" setup_postgresql_db

fetch_and_deploy_gh_release "tolgee" "tolgee/tolgee-platform" "singlefile" "latest" "/opt/tolgee" "tolgee-*.jar"

msg_info "Setting up Tolgee"
mkdir -p /opt/tolgee_data
find /opt/tolgee -maxdepth 1 -type f -name 'tolgee-*.jar' -exec mv {} /opt/tolgee/tolgee.jar \;

cat <<EOF >/opt/tolgee_data/.env
SERVER_PORT=8080
TOLGEE_POSTGRES_AUTOSTART_ENABLED=false
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/${PG_DB_NAME}
SPRING_DATASOURCE_USERNAME=${PG_DB_USER}
SPRING_DATASOURCE_PASSWORD=${PG_DB_PASS}
TOLGEE_AUTHENTICATION_ENABLED=true
TOLGEE_AUTHENTICATION_INITIAL_USERNAME=admin
TOLGEE_FILE_STORAGE_FS_DATA_PATH=/opt/tolgee_data
EOF
msg_ok "Set up Tolgee"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/tolgee.service
[Unit]
Description=Tolgee Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/tolgee
EnvironmentFile=/opt/tolgee_data/.env
ExecStart=/usr/bin/java -jar /opt/tolgee/tolgee
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tolgee
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
