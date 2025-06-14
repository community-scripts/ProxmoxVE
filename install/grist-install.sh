#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: cfurrow
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gristlabs/grist-core

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y make ca-certificates
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv
NODE_VERSION="22" NODE_MODULE="yarn@latest" install_node_and_modules

msg_info "Installing Grist"
RELEASE=$(curl -fsSL https://api.github.com/repos/gristlabs/grist-core/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
export CYPRESS_INSTALL_BINARY=0
export NODE_OPTIONS="--max-old-space-size=2048"
cd /opt
curl -fsSL "https://github.com/gristlabs/grist-core/archive/refs/tags/v${RELEASE}.zip" -o "v${RELEASE}.zip"
$STD unzip "v${RELEASE}.zip"
mv "grist-core-${RELEASE}" /opt/grist
cd /opt/grist
$STD uv venv /opt/grist/sandbox_venv3
$STD /opt/grist/sandbox_venv3/bin/python -m ensurepip --upgrade
$STD /opt/grist/sandbox_venv3/bin/python -m pip install --upgrade pip
$STD /opt/grist/sandbox_venv3/bin/python -m pip install -r sandbox/requirements.txt
$STD yarn install
$STD yarn run build:prod
ln -sf /opt/grist/sandbox_venv3/bin/python3 /opt/grist/sandbox_venv3/bin/python
cat <<EOF >/opt/grist/.env
NODE_ENV=production
GRIST_HOST=0.0.0.0
EOF
echo "${RELEASE}" >/opt/grist_version.txt
msg_ok "Installed Grist"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/grist.service
[Unit]
Description=Grist
After=network.target

[Service]
Type=exec
WorkingDirectory=/opt/grist
ExecStart=/usr/bin/yarn run start:prod
EnvironmentFile=-/opt/grist/.env
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now grist
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "/opt/v${RELEASE}.zip"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
