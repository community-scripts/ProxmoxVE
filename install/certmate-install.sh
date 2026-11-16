#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: fabriziosalmi
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fabriziosalmi/certmate

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.12" setup_uv
fetch_and_deploy_gh_release "certmate" "fabriziosalmi/certmate" "tarball"

msg_info "Installing CertMate Dependencies"
cd /opt/certmate
$STD uv venv --python 3.12 /opt/certmate/.venv
# requirements.lock is the fully pinned set the official image is built from
$STD uv pip sync --python /opt/certmate/.venv/bin/python requirements.lock
$STD /opt/certmate/.venv/bin/certbot --version
msg_ok "Installed CertMate Dependencies"

msg_info "Configuring CertMate"
mkdir -p /opt/certmate_data/{certificates,data,backups,logs}
cat <<EOF >/opt/certmate_data/.env
API_BEARER_TOKEN=$(openssl rand -hex 32)
SECRET_KEY=$(openssl rand -hex 32)
CERTMATE_BACKUP_PASSPHRASE=$(openssl rand -hex 32)
BEHIND_PROXY=false
EOF
chmod 600 /opt/certmate_data/.env
msg_ok "Configured CertMate"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/certmate.service
[Unit]
Description=CertMate SSL Certificate Manager
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/certmate
Environment=PATH=/opt/certmate/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=CERTMATE_CERT_DIR=/opt/certmate_data/certificates
Environment=CERTMATE_DATA_DIR=/opt/certmate_data/data
Environment=CERTMATE_BACKUP_DIR=/opt/certmate_data/backups
Environment=CERTMATE_LOGS_DIR=/opt/certmate_data/logs
Environment=ACME_CHALLENGES_DIR=/opt/certmate_data/data/acme-challenges
EnvironmentFile=/opt/certmate_data/.env
# One worker: the renewal scheduler, sessions and rate limits live in-process
ExecStart=/opt/certmate/.venv/bin/gunicorn --bind 0.0.0.0:8000 --workers 1 --threads 8 --timeout 300 --no-control-socket app:app
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now certmate
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
