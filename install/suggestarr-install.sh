#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/giuseppe99barchetta/SuggestArr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y build-essential
msg_ok "Installed Dependencies"

UV_PYTHON="3.12" setup_uv
NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "suggestarr" "giuseppe99barchetta/SuggestArr" "tarball"

msg_info "Building Frontend"
cd /opt/suggestarr/client
$STD npm install
$STD npm run build
mkdir -p /opt/suggestarr/static
cp -r /opt/suggestarr/client/dist/* /opt/suggestarr/static/
cp -r /opt/suggestarr/client/node_modules/swagger-ui-dist /opt/suggestarr/static/swagger-ui
msg_ok "Built Frontend"

msg_info "Setting up Python Environment"
cd /opt/suggestarr
$STD uv venv --python 3.12 /opt/suggestarr/.venv
$STD uv pip install --python /opt/suggestarr/.venv -r /opt/suggestarr/api_service/requirements.txt
msg_ok "Set up Python Environment"

msg_info "Configuring SuggestArr"
mkdir -p /opt/suggestarr_data
cat <<EOF >/opt/suggestarr.env
SUGGESTARR_PORT=5000
LOG_LEVEL=info
CONFIG_DIR=/opt/suggestarr_data
EOF
chmod 600 /opt/suggestarr.env
msg_ok "Configured SuggestArr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/suggestarr.service
[Unit]
Description=SuggestArr
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/suggestarr
EnvironmentFile=/opt/suggestarr.env
ExecStart=/opt/suggestarr/.venv/bin/uvicorn api_service.app:asgi_app --host 0.0.0.0 --port 5000 --log-level info
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now suggestarr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
