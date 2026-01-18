#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/thingsboard/thingsboard

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  libharfbuzz0b \
  fontconfig \
  fonts-dejavu-core
msg_ok "Installed Dependencies"

JAVA_VERSION="17" setup_java
PG_VERSION="16" setup_postgresql
PG_DB_NAME="thingsboard_db" PG_DB_USER="thingsboard" setup_postgresql_db
fetch_and_deploy_gh_release "thingsboard" "thingsboard/thingsboard" "binary" "latest" "/tmp" "thingsboard-*.deb"

msg_info "Configuring ThingsBoard"
cat <<EOF >/etc/thingsboard/conf/thingsboard.conf <<EOF
# DB Configuration
export DATABASE_TS_TYPE=sql
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/${PG_DB_NAME}
export SPRING_DATASOURCE_USERNAME=${PG_DB_USER}
export SPRING_DATASOURCE_PASSWORD=${PG_DB_PASS}
# Specify partitioning size for timestamp key-value storage. Allowed values: DAYS, MONTHS, YEARS, INDEFINITE.
export SQL_POSTGRES_TS_KV_PARTITIONING=MONTHS
EOF
systemctl daemon-reload
msg_ok "Configured ThingsBoard"

msg_info "Running ThingsBoard Installation Script"
$STD /usr/share/thingsboard/bin/install/install.sh --loadDemo
msg_ok "Ran Installation Script"

msg_info "Starting ThingsBoard Service"
systemctl enable -q --now thingsboard
msg_ok "Started ThingsBoard Service"

motd_ssh
customize
cleanup_lxc
