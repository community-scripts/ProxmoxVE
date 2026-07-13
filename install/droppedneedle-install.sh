#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner | vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://droppedneedle.com/ | Github: https://github.com/DroppedNeedle/DroppedNeedle

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.13" setup_uv
fetch_and_deploy_gh_release "DroppedNeedle" "DroppedNeedle/DroppedNeedle" "tarball"
NODE_VERSION="25" NODE_MODULE="pnpm@10.33.0" setup_nodejs

msg_info "Building Frontend"
cd /opt/droppedneedle/frontend
export NODE_OPTIONS="--max-old-space-size=3072"
$STD pnpm install --frozen-lockfile
$STD pnpm run build
msg_ok "Built Frontend"

msg_info "Setting up Application"
mkdir -p /opt/droppedneedle/backend/config /opt/droppedneedle/backend/cache
$STD uv venv /opt/droppedneedle/venv
$STD uv pip install -r /opt/droppedneedle/backend/requirements.txt --python=/opt/droppedneedle/venv/bin/python
rm -rf /opt/droppedneedle/backend/static
cp -r /opt/droppedneedle/frontend/build /opt/droppedneedle/backend/static
msg_ok "Set up Application"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/droppedneedle.service
[Unit]
Description=DroppedNeedle Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/droppedneedle/backend
Environment=ROOT_APP_DIR=/opt/droppedneedle/backend
Environment=PORT=8688
# Environment=SLSKD_DOWNLOADS_PATH=<path-to-slskd-downloads>
ExecStart=/opt/droppedneedle/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8688 --loop uvloop --http httptools --workers 1
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now droppedneedle
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
