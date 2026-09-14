#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/karanhudia/borg-ui

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
  python3-dev \
  pkg-config \
  libffi-dev \
  libssl-dev \
  libacl1-dev \
  liblz4-dev \
  libzstd-dev \
  libxxhash-dev \
  libfuse3-dev \
  fuse3 \
  rsync \
  sshfs \
  openssh-client
msg_ok "Installed Dependencies"

UV_PYTHON="3.12" setup_uv
NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "borg-ui" "karanhudia/borg-ui" "tarball"

# Only the three Borg pins appear in every release of this file; PYTHON_VERSION
# and RCLONE_VERSION were added upstream after v2.2.6, so both fall back.
RUNTIME_ENV="/opt/borg-ui/docker/runtime-base.env"
BORG1_VERSION=$(sed -n 's/^BORG1_VERSION=//p' "$RUNTIME_ENV" 2>/dev/null | tr -d ' \r')
BORG2_VERSION=$(sed -n 's/^BORG2_VERSION=//p' "$RUNTIME_ENV" 2>/dev/null | tr -d ' \r')
BORGSTORE_VERSION=$(sed -n 's/^BORGSTORE_VERSION=//p' "$RUNTIME_ENV" 2>/dev/null | tr -d ' \r')
RCLONE_VERSION=$(sed -n 's/^RCLONE_VERSION=//p' "$RUNTIME_ENV" 2>/dev/null | tr -d ' \r')
BORG_PYTHON=$(sed -n 's/^PYTHON_VERSION=//p' "$RUNTIME_ENV" 2>/dev/null | tr -d ' \r')
BORG_PYTHON="${BORG_PYTHON:-3.12}"
if [[ -z "$BORG1_VERSION" || -z "$BORG2_VERSION" || -z "$BORGSTORE_VERSION" ]]; then
  msg_error "Could not read the pinned Borg versions from ${RUNTIME_ENV}"
  exit 1
fi

msg_info "Installing Borg ${BORG1_VERSION} and Borg ${BORG2_VERSION} (Patience)"
$STD uv venv --python "$BORG_PYTHON" /opt/borg1-venv
$STD uv pip install --python /opt/borg1-venv pyfuse3 "borgbackup==${BORG1_VERSION}"
echo "$BORG1_VERSION" >/opt/borg1-venv/.pinned_version
$STD uv venv --python "$BORG_PYTHON" /opt/borg2-venv
$STD uv pip install --python /opt/borg2-venv pyfuse3 "borgbackup==${BORG2_VERSION}" "borgstore[rclone,sftp,rest,s3,blake3]==${BORGSTORE_VERSION}"
echo "${BORG2_VERSION}-${BORGSTORE_VERSION}" >/opt/borg2-venv/.pinned_version
ln -sf /opt/borg1-venv/bin/borg /usr/local/bin/borg
ln -sf /opt/borg2-venv/bin/borg /usr/local/bin/borg2
msg_ok "Installed Borg ${BORG1_VERSION} and Borg ${BORG2_VERSION}"

RCLONE_TAG="${RCLONE_VERSION:+v${RCLONE_VERSION}}"
fetch_and_deploy_gh_release "rclone" "rclone/rclone" "prebuild" "${RCLONE_TAG:-latest}" "/opt/rclone" "rclone-${RCLONE_TAG:-*}-linux-$(arch_resolve amd64 arm64).zip"
ln -sf /opt/rclone/rclone /usr/local/bin/rclone

msg_info "Building Frontend"
cd /opt/borg-ui/frontend
$STD npm ci
$STD npm run build
mkdir -p /opt/borg-ui/app/static
cp -r /opt/borg-ui/frontend/build/* /opt/borg-ui/app/static/
msg_ok "Built Frontend"

msg_info "Setting up Python Environment"
cd /opt/borg-ui
$STD uv venv --python "$BORG_PYTHON" /opt/borg-ui/.venv
$STD uv pip install --python /opt/borg-ui/.venv -r requirements.txt
msg_ok "Set up Python Environment"

msg_info "Configuring Borg-UI"
mkdir -p /opt/borg-ui_data
BORG_UI_VERSION=$(cat "$HOME/.borg-ui" 2>/dev/null)
if [[ -z "$BORG_UI_VERSION" ]]; then
  msg_error "Could not determine the deployed Borg-UI version"
  exit 1
fi
cat <<EOF >/opt/borg-ui/.env
APP_VERSION=${BORG_UI_VERSION}
PORT=8081
ENVIRONMENT=production
TZ=UTC
DATA_DIR=/opt/borg-ui_data
ENABLE_CRON_BACKUPS=true
ENABLE_STARTUP_LICENSE_SYNC=false
EOF
chmod 600 /opt/borg-ui/.env
msg_ok "Configured Borg-UI"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/borg-ui.service
[Unit]
Description=Borg-UI
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/borg-ui
EnvironmentFile=/opt/borg-ui/.env
ExecStart=/opt/borg-ui/.venv/bin/gunicorn app.main:app --bind 0.0.0.0:8081 --workers 2 --worker-class uvicorn.workers.UvicornWorker --timeout 300
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now borg-ui
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
