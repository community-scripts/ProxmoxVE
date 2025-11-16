#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.metabase.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

JAVA_VERSION="21" setup_java
PG_VERSION="17" setup_postgresql
PG_DB_NAME="metabase_db" PG_DB_USER="metabase" setup_postgresql_db

msg_info "Setting up Metabase"
mkdir -p /opt/metabase
RELEASE=$(get_latest_github_release "metabase/metabase")
curl -fsSL "https://downloads.metabase.com/v${RELEASE}.x/metabase.jar" -o /opt/metabase/metabase.jar
cd /opt/metabase

cat <<EOF >/opt/metabase/.env
MB_DB_TYPE=postgres
MB_DB_DBNAME=$PG_DB_NAME
MB_DB_PORT=5432
MB_DB_USER=$PG_DB_USER
MB_DB_PASS=$PG_DB_PASS
MB_DB_HOST=localhost
EOF
echo $RELEASE >~/.metabase
msg_ok "Setup Metabase"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/metabase.service
[Unit]
Description=Metabase Service
After=network.target

[Service]
EnvironmentFile=/opt/metabase/.env
WorkingDirectory=/opt/metabase
ExecStart=/usr/bin/java --add-opens java.base/java.nio=ALL-UNNAMED -jar metabase.jar
Restart=always
SuccessExitStatus=143
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now metabase
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
