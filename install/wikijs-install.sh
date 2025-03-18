#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://js.wiki/

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
  git \
  gpg
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
$STD npm install --global yarn
$STD npm install -g node-gyp
msg_ok "Installed Node.js"

msg_info "Set up PostgreSQL"
$STD apt-get install -y postgresql-17
DB_NAME="wiki"
DB_USER="wikijs_user"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" $DB_NAME
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC';"
{
    echo "WikiJS-Credentials"
    echo "WikiJS Database User: $DB_USER"
    echo "WikiJS Database Password: $DB_PASS"
    echo "WikiJS Database Name: $DB_NAME"
} >> ~/wikijs.creds
msg_ok "Set up PostgreSQL"

msg_info "Setup Wiki.js"
temp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/Requarks/wiki/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/requarks/wiki/releases/download/v${RELEASE}/wiki-js.tar.gz" -O "$temp_file"
mkdir /opt/wikijs
tar -xzf "$temp_file" -C /opt/wikijs
mv /opt/wikijs/config.sample.yml /opt/wikijs/config.yml
sed -i -E 's|^( *user: ).*|\1'"$DB_USER"'|' /opt/wikijs/config.yml
sed -i -E 's|^( *pass: ).*|\1'"$DB_PASS"'|' /opt/wikijs/config.yml
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Wiki.js"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wikijs.service
[Unit]
Description=Wiki.js
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node server
Restart=always
User=root
Environment=NODE_ENV=production
WorkingDirectory=/opt/wikijs

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wikijs
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"