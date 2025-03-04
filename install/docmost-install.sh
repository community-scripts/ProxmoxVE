#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docmost.com/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  gpg \
  curl \
  sudo \
  redis \
  make \
  mc \
  postgresql
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g pnpm
msg_ok "Installed Node.js"

msg_info "Setting up PostgreSQL"
DB_NAME="docmost_db"
DB_USER="docmost_user"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC'"
{
    echo "Docmost-Credentials"
    echo "Database Name: $DB_NAME"
    echo "Database User: $DB_USER"
    echo "Database Password: $DB_PASS"
} >> ~/docmost.creds
msg_ok "Set up PostgreSQL"

msg_info "Installing Docmost (Patience)"
temp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/docmost/docmost/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/docmost/docmost/archive/refs/tags/v${RELEASE}.tar.gz" -O "$temp_file"
tar -xzf "$temp_file"
mv docmost-${RELEASE} /opt/docmost
cd /opt/docmost
mv .env.example .env
mkdir data
sed -i -e "s|APP_SECRET=.*|APP_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)|" \
       -e "s|DATABASE_URL=.*|DATABASE_URL=postgres://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME|" \
       -e "s|FILE_UPLOAD_SIZE_LIMIT=.*|FILE_UPLOAD_SIZE_LIMIT=50mb|" \
       /opt/docmost/.env
export NODE_OPTIONS="--max-old-space-size=2048"
$STD pnpm install
$STD pnpm build
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Docmost"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/docmost.service
[Unit]
Description=Docmost Service
After=network.target postgresql.service

[Service]
WorkingDirectory=/opt/docmost
ExecStart=/usr/bin/pnpm start
Restart=always
EnvironmentFile=/opt/docmost/.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now docmost
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
