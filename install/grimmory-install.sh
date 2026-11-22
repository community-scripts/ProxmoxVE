#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/grimmory-tools/grimmory

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_ffmpeg
JAVA_VERSION="25" setup_java
setup_mariadb
MARIADB_DB_NAME="grimmory" MARIADB_DB_USER="grimmory" MARIADB_DB_CREDS_FILE="/dev/null" setup_mariadb_db
fetch_and_deploy_gh_release "kepubify" "pgaskin/kepubify" "singlefile" "latest" "/usr/local/bin" "kepubify-linux-64bit"
USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "grimmory" "grimmory-tools/grimmory" "singlefile" "latest" "/opt/grimmory" "grimmory.jar"

msg_info "Configuring Grimmory"
mkdir -p /opt/grimmory_data/{data,books,bookdrop}
cat <<EOF >/opt/grimmory_data/.env
DATABASE_HOST=localhost
DATABASE_NAME=${MARIADB_DB_NAME}
DATABASE_USERNAME=${MARIADB_DB_USER}
DATABASE_PASSWORD=${MARIADB_DB_PASS}
APP_PATH_CONFIG=/opt/grimmory_data/data
APP_BOOKDROP_FOLDER=/opt/grimmory_data/bookdrop
SERVER_PORT=6060
EOF
chmod 600 /opt/grimmory_data/.env
msg_ok "Configured Grimmory"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/grimmory.service
[Unit]
Description=Grimmory
After=network.target mariadb.service
Requires=mariadb.service

[Service]
Type=simple
WorkingDirectory=/opt/grimmory_data
EnvironmentFile=/opt/grimmory_data/.env
ExecStart=/usr/bin/java -XX:+UseCompactObjectHeaders -XX:MaxRAMPercentage=60.0 -XX:+ExitOnOutOfMemoryError -XX:-UseBASE64Intrinsics --enable-native-access=ALL-UNNAMED --enable-preview -jar /opt/grimmory/grimmory.jar
SuccessExitStatus=143
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now grimmory
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
