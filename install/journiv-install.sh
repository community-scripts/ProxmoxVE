#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/journiv/journiv-app

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
  libffi-dev \
  libpq-dev \
  libmagic1 \
  libheif1 \
  libde265-0 \
  libpango-1.0-0 \
  libpangoft2-1.0-0 \
  redis-server
systemctl enable -q --now redis-server
msg_ok "Installed Dependencies"

setup_ffmpeg
PG_VERSION="17" setup_postgresql
PG_DB_NAME="journiv" PG_DB_USER="journiv" setup_postgresql_db
UV_PYTHON="3.12" setup_uv

fetch_and_deploy_gh_release "journiv" "journiv/journiv-app" "tarball"

msg_info "Setting up Python Environment"
cd /opt/journiv
$STD uv sync --locked --no-editable --no-install-project
msg_ok "Set up Python Environment"

msg_info "Configuring Journiv"
mkdir -p /opt/journiv_data/{media,logs,exports,imports/temp}
cat <<EOF >/opt/journiv.env
ENVIRONMENT=production
SECRET_KEY=$(openssl rand -hex 32)
DB_DRIVER=postgres
DATABASE_URL=postgresql://journiv:${PG_DB_PASS}@localhost:5432/journiv
REDIS_URL=redis://127.0.0.1:6379/0
MEDIA_ROOT=/opt/journiv_data/media
LOG_DIR=/opt/journiv_data/logs
EXPORT_DIR=/opt/journiv_data/exports
IMPORT_TEMP_DIR=/opt/journiv_data/imports/temp
DOMAIN_NAME=${LOCAL_IP}
DOMAIN_SCHEME=http
PYTHONPATH=/opt/journiv
EOF
chmod 600 /opt/journiv.env
msg_ok "Configured Journiv"

msg_info "Initializing Database"
set -a
source /opt/journiv.env
set +a
$STD /opt/journiv/.venv/bin/python -c "from alembic.config import main; main(['upgrade', 'head'])"
SKIP_DATA_SEEDING=false $STD /opt/journiv/.venv/bin/python -c "from app.core.database import seed_initial_data; seed_initial_data()"
msg_ok "Initialized Database"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/journiv.service
[Unit]
Description=Journiv
Wants=network-online.target
After=network-online.target postgresql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/journiv
EnvironmentFile=/opt/journiv.env
ExecStart=/opt/journiv/.venv/bin/python -m gunicorn app.main:app -w 2 -k uvicorn.workers.UvicornWorker --timeout 300 -b 0.0.0.0:8000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/journiv-worker.service
[Unit]
Description=Journiv Celery Worker
Wants=network-online.target
After=network-online.target journiv.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/journiv
EnvironmentFile=/opt/journiv.env
ExecStart=/opt/journiv/.venv/bin/python -m celery -A app.core.celery_app worker --loglevel=info
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/journiv-beat.service
[Unit]
Description=Journiv Celery Beat
Wants=network-online.target
After=network-online.target journiv.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/journiv
EnvironmentFile=/opt/journiv.env
ExecStart=/opt/journiv/.venv/bin/python -m celery -A app.core.celery_app beat --loglevel=info --scheduler redbeat.RedBeatScheduler --pidfile=/run/journiv-beat.pid
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now journiv journiv-worker journiv-beat
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
