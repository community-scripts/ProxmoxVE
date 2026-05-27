#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://musicseerr.com/ | Github: https://github.com/HabiRabbu/Musicseerr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.13" setup_uv
fetch_and_deploy_gh_release "musicseerr" "HabiRabbu/Musicseerr" "tarball"
NODE_VERSION="22" NODE_MODULE="pnpm@10.33.0" setup_nodejs

msg_info "Building Frontend"
cd /opt/musicseerr/frontend
export NODE_OPTIONS="--max-old-space-size=3072"
$STD pnpm install --frozen-lockfile
$STD pnpm run build
msg_ok "Built Frontend"

msg_info "Setting up Application"
mkdir -p /opt/musicseerr/backend/config /opt/musicseerr/backend/cache
$STD uv venv /opt/musicseerr/venv
$STD uv pip install -r /opt/musicseerr/backend/requirements.txt --python=/opt/musicseerr/venv/bin/python
rm -rf /opt/musicseerr/backend/static
cp -r /opt/musicseerr/frontend/build /opt/musicseerr/backend/static
msg_ok "Set up Application"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/musicseerr.service
[Unit]
Description=MusicSeerr Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/musicseerr/backend
Environment=ROOT_APP_DIR=/opt/musicseerr/backend
Environment=PORT=8688
ExecStart=/opt/musicseerr/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8688 --loop uvloop --http httptools --workers 1
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now musicseerr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
