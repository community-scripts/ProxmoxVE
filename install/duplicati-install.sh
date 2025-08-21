#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/duplicati/duplicati/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  libice6 \
  libsm6 \
  libfontconfig1
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "duplicati" "duplicati/duplicati" "binary" "latest" "/opt/duplicati" "duplicati-*-linux-x64-gui.deb"

msg_info "Configuring duplicati"
DECRYPTKEY=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
ADMINPASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
{
  echo "Admin password = ${ADMINPASS}"
  echo "Database encryption key = ${DECRYPTKEY}"
} >>~/duplicati.creds
msg_ok "Configured duplicati"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/duplicati.service
[Unit]
Description=Duplicati Service
After=network.target

[Service]
ExecStart=/usr/bin/duplicati-server --webservice-interface=any --webservice-password=$ADMINPASS --settings-encryption-key=$DECRYPTKEY
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now duplicati
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
