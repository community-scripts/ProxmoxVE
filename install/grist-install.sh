#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: cfurrow | Co-Author: Slaviša Arežina (tremor021)
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
  python3-venv
msg_ok "Installed Dependencies"
NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs
fetch_and_deploy_gh_release "grist" "gristlabs/grist-core" "tarball"

msg_info "Installing Grist"
export CYPRESS_INSTALL_BINARY=0
export NODE_OPTIONS="--max-old-space-size=2048"
cd /opt/grist
$STD yarn install
$STD yarn run build:prod
$STD yarn run install:python
cat <<EOF >/opt/grist/.env
NODE_ENV=production
GRIST_HOST=0.0.0.0
EOF
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
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
