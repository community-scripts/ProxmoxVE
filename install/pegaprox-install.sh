#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/PegaProx/project-pegaprox

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y sshpass
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv

fetch_and_deploy_gh_release "pegaprox" "PegaProx/project-pegaprox" "tarball"

msg_info "Setting up Python Environment"
$STD uv venv --python 3.12 /opt/pegaprox/venv
$STD uv pip install --python /opt/pegaprox/venv/bin/python -r /opt/pegaprox/requirements.txt
msg_ok "Set up Python Environment"

msg_info "Generating Master Key"
mkdir -p /etc/pegaprox
cat <<EOF >/etc/pegaprox/secret.key
$(openssl rand -base64 32 | tr '+/' '-_')
EOF
chmod 600 /etc/pegaprox/secret.key
msg_ok "Generated Master Key"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/pegaprox.service
[Unit]
Description=PegaProx - Multi-Cluster Proxmox VE Management
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/pegaprox
ExecStart=/opt/pegaprox/venv/bin/python /opt/pegaprox/pegaprox_multi_cluster.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pegaprox
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
