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
$STD apt-get install -y \
  make \
  ca-certificates \
  python3.11-venv
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs

msg_info "Installing Grist"
RELEASE=$(curl -fsSL https://api.github.com/repos/gristlabs/grist-core/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
export CYPRESS_INSTALL_BINARY=0
export NODE_OPTIONS="--max-old-space-size=2048"
cd /opt
curl -fsSL "https://github.com/gristlabs/grist-core/archive/refs/tags/v${RELEASE}.zip" -o "v${RELEASE}.zip"
$STD unzip v$RELEASE.zip
mv grist-core-${RELEASE} grist
cd grist
$STD yarn install
$STD yarn run build:prod
$STD yarn run install:python
cat <<EOF >/opt/grist/.env
NODE_ENV=production
GRIST_HOST=0.0.0.0
EOF
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Grist"

msg_info "Create Service"
cat <<EOF >/etc/systemd/system/grist.service
[Unit]
Description=Grist
After=network.target

[Service]
Type=exec
WorkingDirectory=/opt/grist 
ExecStart=/usr/bin/yarn run start:prod
EnvironmentFile=-/opt/grist/.env

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now grist
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
