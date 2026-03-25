#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Dictionarry-Hub/profilarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  python3-dev \
  libffi-dev \
  libssl-dev \
  git
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv
NODE_VERSION="22" setup_nodejs

msg_info "Creating directories"
mkdir -p /opt/profilarr \
  /config
msg_ok "Created directories"

fetch_and_deploy_gh_release "profilarr" "Dictionarry-Hub/profilarr" "tarball"

msg_info "Installing Python Dependencies"
cd /opt/profilarr/backend
$STD uv venv /opt/profilarr/backend/.venv
sed 's/==/>=/g' requirements.txt >requirements-relaxed.txt
$STD uv pip install --python /opt/profilarr/backend/.venv/bin/python -r requirements-relaxed.txt
rm -f requirements-relaxed.txt
msg_ok "Installed Python Dependencies"

msg_info "Building Frontend"
cd /opt/profilarr/frontend
$STD npm install
$STD npm run build
cp -r dist /opt/profilarr/backend/app/static
msg_ok "Built Frontend"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/profilarr.service
[Unit]
Description=Profilarr - Configuration Management Platform for Radarr/Sonarr
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/profilarr/backend
Environment="PATH=/opt/profilarr/backend/.venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONPATH=/opt/profilarr/backend"
ExecStart=/opt/profilarr/backend/.venv/bin/gunicorn --bind 0.0.0.0:6868 --timeout 600 app.main:create_app()
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now profilarr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
