#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Casvt/Kapowarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y python3-pip
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv
fetch_and_deploy_gh_release "kapowarr" "Casvt/Kapowarr"

msg_info "Setup Kapowarr"
cd /opt/kapowarr
$STD uv venv .venv
$STD source .venv/bin/activate
$STD uv pip install --upgrade pip
$STD uv pip install --no-cache-dir -r requirements.txt
msg_ok "Installed Kapowarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/kapowarr.service
[Unit]
Description=Kapowarr Service
After=network.target

[Service]
WorkingDirectory=/opt/kapowarr/
ExecStart=/opt/kapowarr/.venv/bin/python3 Kapowarr.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now kapowarr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
