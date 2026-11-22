#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bytechefhq/bytechef

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

JAVA_VERSION="25" setup_java
NODE_VERSION="24" setup_nodejs
PG_VERSION="16" setup_postgresql
PG_DB_NAME="bytechef" PG_DB_USER="bytechef" setup_postgresql_db

fetch_and_deploy_gh_release "bytechef" "bytechefhq/bytechef" "tarball"

msg_info "Building ByteChef (Patience)"
mv /opt/bytechef /opt/bytechef-build
cd /opt/bytechef-build/client
$STD npm ci
$STD npm run build
cd /opt/bytechef-build
$STD ./gradlew --no-daemon :server:apps:server-app:bootJar -Pprod -Pkotlin.compiler.execution.strategy=in-process
mkdir -p /opt/bytechef/server
mv /opt/bytechef-build/server/apps/server-app/build/libs/server-app-*.jar /opt/bytechef/server/server-app.jar
mv /opt/bytechef-build/client/dist /opt/bytechef/client
rm -rf /opt/bytechef-build
msg_ok "Built ByteChef"

msg_info "Configuring ByteChef"
mkdir -p /opt/bytechef_data/file-storage
cat <<EOF >/opt/bytechef_data/.env
BYTECHEF_DATASOURCE_URL=jdbc:postgresql://localhost:5432/bytechef
BYTECHEF_DATASOURCE_USERNAME=bytechef
BYTECHEF_DATASOURCE_PASSWORD=${PG_DB_PASS}
BYTECHEF_PUBLIC_URL=http://${LOCAL_IP}:8080
BYTECHEF_ANALYTICS_ENABLED=false
BYTECHEF_ENCRYPTION_PROVIDER=property
BYTECHEF_ENCRYPTION_PROPERTY_KEY=$(openssl rand -base64 32)
BYTECHEF_SECURITY_REMEMBER_ME_KEY=$(openssl rand -base64 32)
BYTECHEF_FILE_STORAGE_FILESYSTEM_BASEDIR=/opt/bytechef_data/file-storage
LOGGING_LEVEL_ROOT=INFO
LOGGING_LEVEL_COM_BYTECHEF=INFO
EOF
chmod 600 /opt/bytechef_data/.env
msg_ok "Configured ByteChef"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/bytechef.service
[Unit]
Description=ByteChef
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/bytechef
EnvironmentFile=/opt/bytechef_data/.env
ExecStart=/usr/bin/java -Dfile.encoding=UTF-8 -Duser.timezone=GMT -jar /opt/bytechef/server/server-app.jar
SuccessExitStatus=143
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now bytechef
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
