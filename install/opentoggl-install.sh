#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CorrectRoadH
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CorrectRoadH/opentoggl

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y redis
msg_ok "Installed Dependencies"

PG_VERSION="16" setup_postgresql
PG_DB_NAME="opentoggl" PG_DB_USER="opentoggl" setup_postgresql_db
get_lxc_ip

fetch_and_deploy_gh_release "opentoggl" "CorrectRoadH/opentoggl" "singlefile" "latest" "/usr/local/bin" "opentoggl-linux-amd64"
chmod +x /usr/local/bin/opentoggl

msg_info "Configuring OpenToggl"
mkdir -p /opt/opentoggl
cat <<EOF >/opt/opentoggl/.env
OPENTOGGL_SERVICE_NAME=opentoggl
PORT=8080
DATABASE_URL=postgres://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}?sslmode=disable
REDIS_URL=redis://127.0.0.1:6379/0
OPENTOGGL_FILESTORE_NAMESPACE=opentoggl
OPENTOGGL_JOBS_QUEUE_NAME=default
EOF
msg_ok "Configured OpenToggl"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/opentoggl.service
[Unit]
Description=OpenToggl Service
After=network.target postgresql.service redis.service

[Service]
WorkingDirectory=/opt/opentoggl
EnvironmentFile=/opt/opentoggl/.env
ExecStartPre=/usr/local/bin/opentoggl schema-apply
ExecStart=/usr/local/bin/opentoggl serve
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now redis
systemctl enable -q --now opentoggl
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
