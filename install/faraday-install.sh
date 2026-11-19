#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/infobyte/faraday

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  libpq-dev \
  libmagic1 \
  redis-server
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="faraday" PG_DB_USER="faraday" PG_DB_CREDS_FILE="/dev/null" setup_postgresql_db
PYTHON_VERSION="3.11" setup_uv
fetch_and_deploy_gh_release "faraday" "infobyte/faraday" "tarball"

msg_info "Installing Faraday"
cd /opt/faraday
UV_PROJECT_ENVIRONMENT=/opt/faraday/venv $STD uv sync --frozen --no-dev --no-editable
msg_ok "Installed Faraday"

msg_info "Configuring Faraday"
FARADAY_PASSWORD="${var_faraday_password:-$(random_password)}"
mkdir -p /opt/faraday_data/.faraday/config
cat <<EOF >/opt/faraday_data/.faraday/config/server.ini
[faraday_server]
port = 5985
bind_address = 0.0.0.0
secret_key = $(random_password 32)

[database]
connection_string = postgresql+psycopg2://${PG_DB_USER}:${PG_DB_PASS}@localhost/${PG_DB_NAME}
EOF
cat <<EOF >/opt/faraday_data/.env
FARADAY_HOME=/opt/faraday_data
FARADAY_USER=faraday
FARADAY_PASSWORD=${FARADAY_PASSWORD}
EOF
chmod 600 /opt/faraday_data/.env /opt/faraday_data/.faraday/config/server.ini
FARADAY_HOME=/opt/faraday_data $STD venv/bin/faraday-manage create-tables
FARADAY_HOME=/opt/faraday_data $STD venv/bin/faraday-manage create-superuser --username faraday --email faraday@example.com --password "$FARADAY_PASSWORD"
msg_ok "Configured Faraday"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/faraday-server.service
[Unit]
Description=Faraday Server
After=network.target postgresql.service redis-server.service

[Service]
Type=exec
Environment=FARADAY_HOME=/opt/faraday_data
ExecStart=/opt/faraday/venv/bin/faraday-server
Restart=always

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/faraday-worker.service
[Unit]
Description=Faraday Worker
After=network.target postgresql.service redis-server.service

[Service]
Type=exec
Environment=FARADAY_HOME=/opt/faraday_data
ExecStart=/opt/faraday/venv/bin/faraday-worker
Restart=always

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/faraday-beat.service
[Unit]
Description=Faraday Beat
After=network.target postgresql.service redis-server.service

[Service]
Type=exec
Environment=FARADAY_HOME=/opt/faraday_data
ExecStart=/opt/faraday/venv/bin/faraday-beat
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now faraday-server faraday-worker faraday-beat
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
