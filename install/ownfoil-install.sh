#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: pajjski
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/a1ex4/ownfoil

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y git
msg_ok "Installed Dependencies"

setup_uv
fetch_and_deploy_gh_release "ownfoil" "a1ex4/ownfoil" "tarball"

msg_info "Setting up Ownfoil"
cd /opt/ownfoil
$STD uv venv .venv
$STD source .venv/bin/activate
$STD uv pip install -r requirements.txt
msg_ok "Setup ownfoil"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ownfoil.service
[Unit]
Description=ownfoil Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ownfoil
ExecStart=/opt/ownfoil/.venv/bin/python /opt/ownfoil/app/app.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ownfoil
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
