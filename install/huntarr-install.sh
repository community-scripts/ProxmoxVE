#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: BiluliB
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/plexguide/Huntarr.io

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y jq
msg_ok "Installed Dependencies"

setup_uv
fetch_and_deploy_gh_release "huntarr" "plexguide/Huntarr.io"

msg_info "Configure Huntarr"
$STD uv venv /opt/huntarr/.venv
$STD uv pip install --python /opt/huntarr/.venv/bin/python -r /opt/huntarr/requirements.txt
msg_ok "Configured Huntrarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/huntarr.service
[Unit]
Description=Huntarr Service
After=network.target
[Service]
WorkingDirectory=/opt/huntarr
ExecStart=/opt/huntarr/.venv/bin/python /opt/huntarr/main.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now huntarr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
