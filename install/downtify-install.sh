#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/henriquesebastiao/downtify

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_ffmpeg
PYTHON_VERSION="3.14" setup_uv
NODE_VERSION="26" setup_nodejs
# yt-dlp solves YouTube's JavaScript challenges with Deno
fetch_and_deploy_gh_release "deno" "denoland/deno" "prebuild" "latest" "/usr/local/bin" "deno-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.zip"
fetch_and_deploy_gh_release "downtify" "henriquesebastiao/downtify" "tarball"

msg_info "Building Downtify"
cd /opt/downtify/frontend
$STD npm ci
$STD npm run build
rm -rf /opt/downtify/frontend/node_modules
cd /opt/downtify
# pyproject.toml sets [tool.uv] upgrade = true, so --locked fails whenever PyPI has anything newer than uv.lock
$STD uv sync --frozen --no-dev --python 3.14
msg_ok "Built Downtify"

msg_info "Configuring Downtify"
mkdir -p /opt/downtify_data/{data,downloads}
cat <<EOF >/opt/downtify_data/.env
DATABASE_DIR=/opt/downtify_data/data
DOWNLOAD_DIR=/opt/downtify_data/downloads
EOF
msg_ok "Configured Downtify"

msg_info "Creating Downtify Service"
cat <<EOF >/etc/systemd/system/downtify.service
[Unit]
Description=Downtify
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/downtify
EnvironmentFile=/opt/downtify_data/.env
Environment=WEB_GUI_LOCATION=/opt/downtify/frontend/dist
ExecStart=/opt/downtify/.venv/bin/python /opt/downtify/main.py web
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now downtify
msg_ok "Created Downtify Service"

motd_ssh
customize
cleanup_lxc
