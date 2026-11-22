#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mathesar-foundation/mathesar

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y libcairo2
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="mathesar_django" PG_DB_USER="mathesar" PG_DB_SCHEMA_PERMS="true" setup_postgresql_db
PYTHON_VERSION="3.12" setup_uv
fetch_and_deploy_gh_release "mathesar" "mathesar-foundation/mathesar" "prebuild" "latest" "/opt/mathesar" "mathesar.tar.gz"

msg_info "Installing Mathesar"
cd /opt/mathesar
$STD uv venv --python 3.12 /opt/mathesar/.venv
$STD uv pip install --python /opt/mathesar/.venv/bin/python -r requirements.txt
msg_ok "Installed Mathesar"

msg_info "Configuring Mathesar"
mkdir -p /opt/mathesar_data/media
cat <<EOF >/opt/mathesar_data/.env
SECRET_KEY=$(random_password 50)
ALLOWED_HOSTS=*
WEB_CONCURRENCY=3
MEDIA_ROOT=/opt/mathesar_data/media/
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_DB=mathesar_django
POSTGRES_USER=mathesar
POSTGRES_PASSWORD=${PG_DB_PASS}
EOF
chmod 600 /opt/mathesar_data/.env
set -a
source /opt/mathesar_data/.env
set +a
$STD /opt/mathesar/.venv/bin/python -m mathesar.install
msg_ok "Configured Mathesar"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/mathesar.service
[Unit]
Description=Mathesar
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/mathesar
EnvironmentFile=/opt/mathesar_data/.env
ExecStart=/opt/mathesar/.venv/bin/gunicorn config.wsgi -b 0.0.0.0:8000 --timeout 180
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mathesar
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
