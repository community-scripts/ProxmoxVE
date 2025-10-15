#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/YuukanOO/seelf

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  make \
  gcc
msg_ok "Installed Dependencies"

setup_go
NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "seelf" "YuukanOO/seelf"

msg_info "Setting up seelf. Patience"
cd /opt/seelf
$STD make build
PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
mkdir -p /opt/seelf/data
{
  echo "ADMIN_EMAIL=admin@example.com"
  echo "ADMIN_PASSWORD=$PASS"
} | tee .env ~/seelf.creds >/dev/null
SEELF_ADMIN_EMAIL=admin@example.com SEELF_ADMIN_PASSWORD=$PASS ./seelf serve &>/dev/null &
sleep 5
kill $!
msg_ok "Done setting up seelf"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/seelf.service
[Unit]
Description=seelf Service
After=network.target

[Service]
Type=simple
User=root
Group=root
EnvironmentFile=/opt/seelf/.env
Environment=DATA_PATH=/opt/seelf/data
WorkingDirectory=/opt/seelf
ExecStart=/opt/seelf/./seelf -c data/conf.yml serve
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now seelf
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
