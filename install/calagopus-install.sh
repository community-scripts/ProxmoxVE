#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Jelcoo
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://calagopus.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y valkey
systemctl enable -q --now valkey-server
msg_ok "Installed Dependencies"

PG_VERSION="18" setup_postgresql
PG_DB_NAME="panel" PG_DB_USER="calagopus" setup_postgresql_db

setup_docker

fetch_and_deploy_gh_release "calagopus-panel" "calagopus/panel" "singlefile" "latest" "/usr/local/bin" "panel-rs-aio-$(arch_resolve x86_64 aarch64)-linux"

msg_info "Configuring Calagopus"
mkdir -p /etc/calagopus /var/lib/calagopus /var/log/calagopus
mkdir -p /etc/calagopus-wings /var/lib/calagopus-wings /var/log/calagopus-wings /tmp/calagopus-wings

APP_ENCRYPTION_KEY=$(openssl rand -hex 16)
cat <<EOF >/etc/calagopus/.env
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}
DATABASE_MIGRATE=true
REDIS_URL=redis://localhost
PORT=8000
APP_ENCRYPTION_KEY=${APP_ENCRYPTION_KEY}
APP_LOG_DIRECTORY=/var/log/calagopus
APP_PRIMARY=true
APP_ENABLE_WINGS_PROXY=true
APP_USE_DECRYPTION_CACHE=true
APP_USE_INTERNAL_CACHE=true
AIO_BASE_WINGS_CONFIGURATION=/etc/calagopus/wings-config.yml
EOF
chmod 600 /etc/calagopus/.env

cat <<EOF >/etc/calagopus/wings-config.yml
app_name: Calagopus
EOF
msg_ok "Configured Calagopus"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/calagopus-panel.service
[Unit]
Description=Calagopus Panel
After=network.target postgresql.service valkey-server.service docker.service
Requires=postgresql.service valkey-server.service docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/etc/calagopus
EnvironmentFile=/etc/calagopus/.env
ExecStart=/usr/local/bin/calagopus-panel
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now calagopus-panel
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
