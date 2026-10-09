#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.ankiweb.net/sync-server.html

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

UV_PYTHON="3.12" setup_uv

msg_info "Installing Anki Sync Server"
$STD uv venv --python 3.12 /opt/anki-sync-server/venv
$STD uv pip install --python /opt/anki-sync-server/venv/bin/python "anki==$(get_latest_github_release "ankitects/anki")"
cat <<EOF >~/.anki-sync-server
$(get_latest_github_release "ankitects/anki")
EOF
msg_ok "Installed Anki Sync Server"

msg_info "Configuring Anki Sync Server"
mkdir -p /opt/anki-sync-server/data
cat <<EOF >/opt/anki-sync-server/.env
SYNC_USER1=anki:$(tr -d '-' </proc/sys/kernel/random/uuid)
SYNC_BASE=/opt/anki-sync-server/data
SYNC_HOST=0.0.0.0
SYNC_PORT=8080
EOF
chmod 600 /opt/anki-sync-server/.env
msg_ok "Configured Anki Sync Server"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/anki-sync-server.service
[Unit]
Description=Anki Sync Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/anki-sync-server
EnvironmentFile=/opt/anki-sync-server/.env
ExecStart=/opt/anki-sync-server/venv/bin/python -m anki.syncserver
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now anki-sync-server
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc