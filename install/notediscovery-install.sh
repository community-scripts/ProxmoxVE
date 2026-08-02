#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gamosoft/NoteDiscovery

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_uv

fetch_and_deploy_gh_release "notediscovery" "gamosoft/NoteDiscovery" "tarball"

msg_info "Installing Dependencies"
cd /opt/notediscovery
$STD uv sync --no-dev
msg_ok "Installed Dependencies"

msg_info "Configuring NoteDiscovery"
mkdir -p /opt/notediscovery/data
msg_ok "Configured NoteDiscovery"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/notediscovery.service
[Unit]
Description=NoteDiscovery Knowledge Base
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/notediscovery
ExecStart=/opt/notediscovery/.venv/bin/python /opt/notediscovery/run.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now notediscovery
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
