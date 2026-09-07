#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: luismco
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dullage/flatnotes

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "flatnotes" "dullage/flatnotes" "tarball"
PYTHON_VERSION="3.13" setup_uv
NODE_VERSION="24" setup_nodejs

msg_info "Setting up Flatnotes"
cd /opt/flatnotes
$STD uv sync --locked --no-dev
mkdir -p /opt/flatnotes/data
$STD npm ci
$STD npm run build

cat <<EOF >/opt/flatnotes/.env
FLATNOTES_AUTH_TYPE='none'
FLATNOTES_PATH='/opt/flatnotes/data/'
#FLATNOTES_USERNAME='username'
#FLATNOTES_PASSWORD='password'
#FLATNOTES_SECRET_KEY='secret-key'
EOF
msg_ok "Setup Flatnotes"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/flatnotes.service
[Unit]
Description=Flatnotes
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/flatnotes
EnvironmentFile=/opt/flatnotes/.env
ExecStart=/opt/flatnotes/.venv/bin/python -m uvicorn main:app --app-dir server --host 0.0.0.0 --port 8080 --proxy-headers
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now flatnotes
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
