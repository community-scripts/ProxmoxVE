#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://listmonk.app/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION="17" setup_postgresql

msg_info "Configuring PostgreSQL"
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
} >>~/listmonk.creds
msg_ok "Configured PostgreSQL"

fetch_and_deploy_gh_release "listmonk" "knadh/listmonk" "prebuild" "latest" "/opt/listmonk" "listmonk*linux_amd64.tar.gz"

msg_info "Configuring listmonk"
mkdir -p /opt/listmonk/uploads
$STD /opt/listmonk/listmonk --new-config --config /opt/listmonk/config.toml
sed -i -e 's/address = "localhost:9000"/address = "0.0.0.0:9000"/' -e 's/^password = ".*"/password = "'"$DB_PASS"'"/' /opt/listmonk/config.toml
$STD /opt/listmonk/listmonk --install --yes --config /opt/listmonk/config.toml
msg_ok "Configured listmonk"

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
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
