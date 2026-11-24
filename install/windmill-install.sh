#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/windmill-labs/windmill

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION="18" setup_postgresql
PG_DB_NAME="windmill" PG_DB_USER="windmill" setup_postgresql_db
setup_uv
NODE_VERSION="24" NODE_MODULE="bun" setup_nodejs
fetch_and_deploy_gh_release "windmill" "windmill-labs/windmill" "singlefile" "latest" "/opt/windmill" "windmill-amd64"
USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "windmill-duckdb" "windmill-labs/windmill" "singlefile" "latest" "/opt/windmill" "windmill_duckdb_runner"

msg_info "Creating Windmill Database Roles"
# Windmill's migrations can only create these as superuser (windmill_admin needs BYPASSRLS)
$STD sudo -u postgres psql -c "CREATE ROLE windmill_user; CREATE ROLE windmill_admin WITH BYPASSRLS; GRANT windmill_user TO windmill_admin; GRANT windmill_admin, windmill_user TO windmill;"
msg_ok "Created Windmill Database Roles"

msg_info "Configuring Windmill"
mkdir -p /opt/windmill_data
cat <<EOF >/opt/windmill_data/.env
DATABASE_URL=postgres://windmill:${PG_DB_PASS}@127.0.0.1:5432/windmill?sslmode=disable
MODE=standalone
BASE_URL=http://${LOCAL_IP}:8000
EOF
chmod 600 /opt/windmill_data/.env
msg_ok "Configured Windmill"

msg_info "Creating Windmill Service"
cat <<EOF >/etc/systemd/system/windmill.service
[Unit]
Description=Windmill
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/windmill
EnvironmentFile=/opt/windmill_data/.env
# ~/.windmill is the version file, but Windmill keeps its standalone bundles in \$HOME/.windmill
Environment=HOME=/opt/windmill_data
Environment=WINDMILL_DIR=/opt/windmill_data
ExecStart=/opt/windmill/windmill
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now windmill
msg_ok "Created Windmill Service"

motd_ssh
customize
cleanup_lxc
