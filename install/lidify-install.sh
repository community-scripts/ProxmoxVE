#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Tim Moore (angusmaul)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TheWicklowWolf/Lidify

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.12" setup_uv
fetch_and_deploy_gh_release "lidify" "TheWicklowWolf/Lidify" "tarball"

msg_info "Setting up Lidify"
$STD uv venv --python 3.12 /opt/lidify/.venv
$STD uv pip install --python /opt/lidify/.venv/bin/python -r /opt/lidify/requirements.txt
install -d -m 700 /opt/lidify/config
cat <<EOF >/opt/lidify/.env
RELEASE_VERSION=$(cat ~/.lidify)
EOF
msg_ok "Set up Lidify"

msg_info "Creating Lidify Service"
cat <<EOF >/etc/systemd/system/lidify.service
[Unit]
Description=Lidify
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/lidify
EnvironmentFile=/opt/lidify/.env
ExecStart=/opt/lidify/.venv/bin/gunicorn src.Lidify:app -c gunicorn_config.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now lidify
msg_ok "Created Lidify Service"

motd_ssh
customize
cleanup_lxc
