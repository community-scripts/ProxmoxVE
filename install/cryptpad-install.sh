#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cryptpad/cryptpad

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
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

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Setup Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Setup Node.js"

read -p "Install OnlyOffice components instead of CKEditor? (Y/N): " onlyoffice

msg_info "Setup ${APPLICATION}"
temp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/cryptpad/cryptpad/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q "https://github.com/cryptpad/cryptpad/archive/refs/tags/${RELEASE}.tar.gz" -O $temp_file
tar zxf $temp_file
mv cryptpad-$RELEASE /opt/cryptpad
cd /opt/cryptpad
$STD npm ci
$STD npm run install:components
$STD npm run build
cp config/config.example.js config/config.js
IP=$(hostname -I | awk '{print $1}')
sed -i "51s/localhost/${IP}/g" /opt/cryptpad/config/config.js
sed -i "80s#//httpAddress: 'localhost'#httpAddress: '0.0.0.0'#g" /opt/cryptpad/config/config.js
if [[ "$onlyoffice" =~ ^[Yy]$ ]]; then
    $STD bash -c "./install-onlyoffice.sh --accept-license"
fi
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Setup ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/cryptpad.service
[Unit]
Description=CryptPad Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cryptpad
ExecStart=/usr/bin/node server
Environment='PWD="/opt/cryptpad"'
StandardOutput=journal
StandardError=journal+console
LimitNOFILE=1000000
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cryptpad
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
