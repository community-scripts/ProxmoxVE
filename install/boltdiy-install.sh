#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/stackblitz-labs/bolt.diy/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  gnupg \
  git
msg_ok "Installed Dependencies"

msg_info "Setup Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Setup Node.js Repository"

msg_info "Setup Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g pnpm
msg_ok "Setup Node.js"

msg_info "Setup bolt.diy"
temp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/stackblitz-labs/bolt.diy/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/stackblitz-labs/bolt.diy/archive/refs/tags/v${RELEASE}.tar.gz" -O $temp_file
tar xzf $temp_file
mv bolt.diy-${RELEASE} /opt/bolt.diy
cd /opt/bolt.diy
$STD pnpm install
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Setup bolt.diy"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/boltdiy.service
[Unit]
Description=bolt.diy Service 
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/bolt.diy
ExecStart=/usr/bin/pnpm run dev --host
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now boltdiy
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
