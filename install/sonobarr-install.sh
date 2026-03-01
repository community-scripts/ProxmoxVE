#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: GoldenSpringness
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Dodelidoo-Labs/sonobarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "sonobarr" "Dodelidoo-Labs/sonobarr" "tarball"
PYTHON_VERSION="3.12" setup_uv

msg_info "Setting up sonobarr"
$STD uv venv -c /opt/sonobarr/venv
source /opt/sonobarr/venv/bin/activate
$STD uv pip install --no-cache-dir -r /opt/sonobarr/requirements.txt
mkdir -p /etc/sonobarr
mv /opt/sonobarr/.sample-env /etc/sonobarr/.env
sed -i "s/^secret_key=.*/secret_key=$(openssl rand -hex 16)/" /etc/sonobarr/.env
sed -i "s/^sonobarr_superadmin_password=.*/sonobarr_superadmin_password=$(openssl rand -hex 16)/" /etc/sonobarr/.env
echo "release_version=$(cat ~/.sonobarr)" >>/etc/sonobarr/.env
echo "sonobarr_config_dir=/etc/sonobarr" >>/etc/sonobarr.env
msg_ok "Set up sonobarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/sonobarr.service
[Unit]
Description=sonobarr Service
After=network.target

[Service]
WorkingDirectory=/opt/sonobarr/src
EnvironmentFile=/etc/sonobarr/.env
Environment="PATH=/opt/sonobarr/venv/bin"
ExecStart=/bin/bash -c 'gunicorn Sonobarr:app -c ../gunicorn_config.py'
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now sonobarr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
