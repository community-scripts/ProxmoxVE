#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/plankanban/planka

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt install -y \
  unzip \
  build-essential \
  python3-venv
msg_ok "Installed dependencies"

NODE_VERSION="24" setup_nodejs
PG_VERSION="16" setup_postgresql

PG_DB_NAME="planka" PG_DB_USER="planka" setup_postgresql_db

fetch_and_deploy_gh_release "planka" "plankanban/planka" "prebuild" "latest" "/opt/planka" "planka-prebuild.zip"

msg_info "Configuring PLANKA"
SECRET_KEY=$(openssl rand -hex 64)
cd /opt/planka
$STD npm install
cp .env.sample .env
sed -i "s#http://localhost:1337#http://$LOCAL_IP:1337#g" /opt/planka/.env
sed -i "s#postgres@localhost#planka:$PG_DB_PASS@localhost#g" /opt/planka/.env
sed -i "s#notsecretkey#$SECRET_KEY#g" /opt/planka/.env
mkdir -p /opt/planka/data/protected/{favicons,user-avatars,background-images} /opt/planka/data/private/attachments
$STD npm run db:init
msg_ok "Configured PLANKA"

msg_info "Creating Admin User"
ADMIN_EMAIL="admin@planka.local"
ADMIN_PASSWORD="$(openssl rand -base64 12)"
ADMIN_NAME="Administrator"
ADMIN_USERNAME="admin"
echo "" >>.env
echo "# Temporary admin user creation settings" >>.env
echo "DEFAULT_ADMIN_EMAIL=$ADMIN_EMAIL" >>.env
echo "DEFAULT_ADMIN_PASSWORD=$ADMIN_PASSWORD" >>.env
echo "DEFAULT_ADMIN_NAME=$ADMIN_NAME" >>.env
echo "DEFAULT_ADMIN_USERNAME=$ADMIN_USERNAME" >>.env
$STD npm run db:seed
sed -i '/# Temporary admin user creation settings/,$d' .env
cat <<EOF >>~/planka.creds

PLANKA Admin Credentials
Admin Email: $ADMIN_EMAIL
Admin Password: $ADMIN_PASSWORD
Admin Name: $ADMIN_NAME
Admin Username: $ADMIN_USERNAME
EOF
msg_ok "Created Admin User"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/planka.service
[Unit]
Description=planka Service
After=network.target

[Service]
WorkingDirectory=/opt/planka
ExecStart=/usr/bin/npm start --prod
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now planka
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
