#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

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
  postgresql
msg_ok "Installed Dependencies"

msg_info "Setting up PostgreSQL"
DB_NAME=listmonk
DB_USER=listmonk
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER TEMPLATE template0;"
{
echo "listmonk-Credentials"
echo -e "listmonk Database User: \e[32m$DB_USER\e[0m"
echo -e "listmonk Database Password: \e[32m$DB_PASS\e[0m"
echo -e "listmonk Database Name: \e[32m$DB_NAME\e[0m"
} >> ~/listmonk.creds
msg_ok "Set up PostgreSQL"

msg_info "Installing listmonk"
cd /opt
mkdir /opt/listmonk
mkdir /opt/listmonk/uploads
RELEASE=$(curl -s https://api.github.com/repos/knadh/listmonk/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/knadh/listmonk/releases/download/v${RELEASE}/listmonk_${RELEASE}_linux_amd64.tar.gz"
tar -xzf "listmonk_${RELEASE}_linux_amd64.tar.gz" -C /opt/listmonk

$STD /opt/listmonk/listmonk --new-config --config /opt/listmonk/config.toml
sed -i -e 's/address = "localhost:9000"/address = "0.0.0.0:9000"/' -e 's/^password = ".*"/password = "'"$DB_PASS"'"/' /opt/listmonk/config.toml
$STD /opt/listmonk/listmonk --install --yes --config /opt/listmonk/config.toml

echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed listmonk"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/listmonk.service
[Unit]
Description=Listmonk Service
Wants=network.target
After=postgresql.service

[Service]
Type=simple
ExecStart=/opt/listmonk/listmonk --config /opt/listmonk/config.toml
Restart=always
RestartSec=3
WorkingDirectory=/opt/listmonk

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now listmonk
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "/opt/listmonk_${RELEASE}_linux_amd64.tar.gz"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"