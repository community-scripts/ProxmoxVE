#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/YuukanOO/seelf

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
  make \
  gcc
msg_ok "Installed Dependencies"

msg_info "Installing Golang"
set +o pipefail
temp_file=$(mktemp)
golang_tarball=$(curl -s https://go.dev/dl/ | grep -oP 'go[\d\.]+\.linux-amd64\.tar\.gz' | head -n 1)
wget -q https://golang.org/dl/"$golang_tarball" -O "$temp_file"
tar -C /usr/local -xzf "$temp_file"
ln -sf /usr/local/go/bin/go /usr/local/bin/go
set -o pipefail
msg_ok "Installed Golang"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Setting up seelf. Patience"
RELEASE=$(curl -s https://api.github.com/repos/YuukanOO/seelf/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/YuukanOO/seelf/archive/refs/tags/v${RELEASE}.tar.gz"
tar -xzf v${RELEASE}.tar.gz
mv seelf-${RELEASE}/ /opt/seelf
cd /opt/seelf
$STD make build 
PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
{
    echo "ADMIN_EMAIL=admin@example.com"
    echo "ADMIN_PASSWORD=$PASS"
} | tee .env ~/seelf.creds > /dev/null

echo "${RELEASE}" >/opt/seelf_version.txt
SEELF_ADMIN_EMAIL=admin@example.com SEELF_ADMIN_PASSWORD=$PASS ./seelf serve &> /dev/null & sleep 5 ; kill $!
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
WorkingDirectory=/opt/seelf
ExecStart=/opt/seelf/./seelf serve
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now seelf
msg_ok "Created Service"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
rm -f ~/v${RELEASE}.tar.gz
rm -f $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize 