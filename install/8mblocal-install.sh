#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/JMS1717/8mb.local

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
setup_hwaccel

msg_info "Installing Dependencies"
$STD apt install -y redis-server
msg_ok "Installed Dependencies"

setup_ffmpeg
NODE_VERSION="22" setup_nodejs
PYTHON_VERSION="3.12" setup_uv

fetch_and_deploy_gh_release "8mblocal" "JMS1717/8mb.local" "tarball"

msg_info "Building 8mb.local"
mv /opt/8mblocal /opt/8mblocal-build
cd /opt/8mblocal-build/frontend
$STD npm ci
$STD npm run build
# Same layout as the official image: the worker imports backend.history_manager and Celery includes worker.worker
mkdir -p /opt/8mblocal
mv /opt/8mblocal-build/backend-api/app /opt/8mblocal/backend
mv /opt/8mblocal-build/worker/app /opt/8mblocal/worker
mv /opt/8mblocal-build/shared /opt/8mblocal-build/requirements.txt /opt/8mblocal/
mv /opt/8mblocal-build/frontend/build /opt/8mblocal/frontend-build
rm -rf /opt/8mblocal-build
cd /opt/8mblocal
$STD uv venv --python 3.12 .venv
$STD uv pip install --python .venv/bin/python -r requirements.txt packaging
msg_ok "Built 8mb.local"

msg_info "Configuring 8mb.local"
mkdir -p /opt/8mblocal_data/{uploads/.tmp,outputs,state}
cat <<EOF >/opt/8mblocal_data/.env
AUTH_ENABLED=true
AUTH_USER=admin
AUTH_PASS=$(random_password)
FILE_RETENTION_HOURS=1
MEDIA_STORAGE=disk
WORKER_CONCURRENCY=auto
HISTORY_ENABLED=true
REDIS_URL=redis://127.0.0.1:6379/0
APP_DATA_DIR=/opt/8mblocal_data
ENV_FILE=/opt/8mblocal_data/.env
SETTINGS_FILE=/opt/8mblocal_data/state/settings.json
HISTORY_FILE=/opt/8mblocal_data/state/history.json
TMPDIR=/opt/8mblocal_data/uploads/.tmp
FRONTEND_BUILD_DIR=/opt/8mblocal/frontend-build
BACKEND_APP_ROOT=/opt/8mblocal
EOF
chmod 600 /opt/8mblocal_data/.env
msg_ok "Configured 8mb.local"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/8mblocal-worker.service
[Unit]
Description=8mb.local Worker
After=network.target redis-server.service
Requires=redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/8mblocal
EnvironmentFile=/opt/8mblocal_data/.env
Environment=PYTHONPATH=/opt/8mblocal
ExecStart=/opt/8mblocal/.venv/bin/celery -A worker.celery_app worker --loglevel=info
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/8mblocal.service
[Unit]
Description=8mb.local
After=network.target redis-server.service 8mblocal-worker.service
Requires=redis-server.service
Wants=8mblocal-worker.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/8mblocal
EnvironmentFile=/opt/8mblocal_data/.env
Environment=PYTHONPATH=/opt/8mblocal
ExecStart=/opt/8mblocal/.venv/bin/uvicorn backend.main:app --host 0.0.0.0 --port 8001
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now 8mblocal-worker 8mblocal
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
