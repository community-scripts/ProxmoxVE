#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/outline/outline

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
mkcert \
git \
redis
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Setting up PostgreSQL Repository"
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
echo "deb https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" >/etc/apt/sources.list.d/pgdg.list
msg_ok "Set up PostgreSQL Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g yarn
msg_ok "Installed Node.js"

msg_info "Install/Set up PostgreSQL Database"
$STD apt-get install -y postgresql-16
DB_NAME="outline"
DB_USER="outline"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
SECRET_KEY="$(openssl rand -hex 32)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC';"
msg_ok "Set up PostgreSQL"

msg_info "Setup Outline (Patience)"
temp_file=$(mktemp)
LOCAL_IP="$(hostname -I | awk '{print $1}')"
RELEASE=$(curl -s https://api.github.com/repos/outline/outline/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/outline/outline/archive/refs/tags/v${RELEASE}.tar.gz" -O $temp_file
tar zxf $temp_file
mv outline-${RELEASE} /opt/outline
cd /opt/outline
cp .env.sample .env
sed -i 's/NODE_ENV=production/NODE_ENV=development/g' /opt/outline/.env
sed -i "s/generate_a_new_key/${SECRET_KEY}/g" /opt/outline/.env
sed -i "s/user:pass@postgres/${DB_USER}:${DB_PASS}@localhost/g" /opt/outline/.env
sed -i 's/redis:6379/localhost:6379/g' /opt/outline/.env
sed -i "32s#URL=#URL=http://${LOCAL_IP}#g" /opt/outline/.env
sed -i 's/FORCE_HTTPS=true/FORCE_HTTPS=false/g' /opt/outline/.env
$STD yarn install --frozen-lockfile
export NODE_OPTIONS="--max-old-space-size=3584"
$STD yarn build
sed -i 's/NODE_ENV=development/NODE_ENV=production/g' /opt/outline/.env
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Setup Outline"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/outline.service
[Unit]
Description=Outline Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/outline
ExecStart=/usr/bin/node ./build/server/index.js
Restart=always
EnvironmentFile=/opt/outline/.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now outline
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"