#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/inngest/inngest

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y redis-server
sed -i 's/^appendonly no/appendonly yes/' /etc/redis/redis.conf
systemctl restart redis-server
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="inngest" PG_DB_USER="inngest" setup_postgresql_db
fetch_and_deploy_gh_release "inngest" "inngest/inngest" "prebuild" "latest" "/opt/inngest" "inngest_*_linux_$(arch_resolve).tar.gz"

msg_info "Configuring Inngest"
mkdir -p /opt/inngest_data
cat <<EOF >/opt/inngest_data/.env
INNGEST_PORT=8288
INNGEST_POSTGRES_URI=postgres://inngest:${PG_DB_PASS}@127.0.0.1:5432/inngest?sslmode=disable
INNGEST_REDIS_URI=redis://127.0.0.1:6379
INNGEST_EVENT_KEY=$(openssl rand -hex 32)
INNGEST_SIGNING_KEY=$(openssl rand -hex 32)
DO_NOT_TRACK=1
EOF
chmod 600 /opt/inngest_data/.env
msg_ok "Configured Inngest"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/inngest.service
[Unit]
Description=Inngest
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/inngest_data
EnvironmentFile=/opt/inngest_data/.env
ExecStart=/opt/inngest/inngest start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now inngest
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
