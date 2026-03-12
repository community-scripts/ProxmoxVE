#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: community-scripts
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pegaprox.com | https://github.com/PegaProx/project-pegaprox

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  python3 \
  python3-pip \
  python3-venv \
  curl \
  wget \
  git \
  openssl \
  sshpass \
  ca-certificates \
  sqlite3
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "pegaprox" "PegaProx/project-pegaprox" "tarball" "latest" "/opt/PegaProx"

msg_info "Setting up Python Virtual Environment"
cd /opt/PegaProx || exit
python3 -m venv /opt/PegaProx/venv
$STD /opt/PegaProx/venv/bin/pip install --upgrade pip
$STD /opt/PegaProx/venv/bin/pip install -r requirements.txt
msg_ok "Set up Python Virtual Environment"

msg_info "Creating Directories"
mkdir -p /opt/PegaProx/{config,logs,ssl,static,web,images,backups}
chmod 700 /opt/PegaProx/config
chmod 700 /opt/PegaProx/ssl
msg_ok "Created Directories"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/pegaprox.service
[Unit]
Description=PegaProx - Proxmox Cluster Management
After=network.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/PegaProx
Environment=PATH=/opt/PegaProx/venv/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/opt/PegaProx/venv/bin/python /opt/PegaProx/pegaprox_multi_cluster.py
Restart=always
RestartSec=5
AmbientCapabilities=CAP_NET_BIND_SERVICE
PrivateTmp=true
StandardOutput=journal
StandardError=journal
SyslogIdentifier=pegaprox

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pegaprox
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
