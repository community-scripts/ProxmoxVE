#!/usr/bin/env bash

# Copyright (c) 2024 community-scripts ORG
# Author: Gerhard Burger (burgerga)
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
  sudo \
  mc \
  curl \
  lsb-release \
  postgresql \
  gnupg \
  unzip
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
wget -qO- https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Setting up Redis Repository"
wget -qO- https://packages.redis.io/gpg | gpg --dearmor -o /etc/apt/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" >/etc/apt/sources.list.d/redis.list
msg_ok "Set up Redis Repository"

msg_info "Installing Node.js/Yarn"
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g yarn
msg_ok "Installed Node.js/Yarn"

msg_info "Installing Redis"
$STD apt-get install -y redis
sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf
systemctl enable -q --now redis-server.service
msg_ok "Installed Redis"

msg_info "Setting up PostgreSQL DB"
SECRET_KEY="$(openssl rand -hex 32)"
UTILS_SECRET="$(openssl rand -hex 32)"
DB_NAME=outlinedb
DB_USER=outline
DB_PASS="$(openssl rand -base64 18 | tr -d '/' | cut -c1-13)"
DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER WITH CREATEDB;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC';"

{
    echo "Outline-Credentials"
    echo "Outline Database User: $DB_USER"
    echo "Outline Database Password: $DB_PASS"
    echo "Outline Database Name: $DB_NAME"
    echo "Outline Secret: $SECRET_KEY"
    echo "Outline Utils Secret: $UTILS_SECRET"
} >~/outline.creds
msg_ok "Set up PostgreSQL DB"


read -r -p "Would you like to add Adminer? <y/N> " adminer_prompt
if [[ "${adminer_prompt,,}" =~ ^(y|yes)$ ]]; then
  msg_info "Installing Adminer"
  $STD apt install -y adminer
  $STD a2enconf adminer
  systemctl reload apache2
  IP=$(hostname -I | awk '{print $1}')
  {
      echo ""
      echo "Adminer Interface: $IP/adminer/"
      echo "Adminer System: PostgreSQL"
      echo "Adminer Server: localhost:5432"
      echo "Adminer Username: $DB_USER"
      echo "Adminer Password: $DB_PASS"
      echo "Adminer Database: $DB_NAME"
  } >>~/outline.creds
  msg_ok "Installed Adminer"
fi

msg_info "Installing Outline (Patience)"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/outline/outline/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/outline/outline/archive/refs/tags/v${RELEASE}.zip"
unzip -q v${RELEASE}.zip
mv outline-${RELEASE} /opt/outline
cd /opt/outline

$STD yarn install --no-optional --frozen-lockfile
$STD yarn cache clean
$STD yarn build

rm -rf ./node_modules
$STD yarn install --production=true --frozen-lockfile
$STD yarn cache clean

mkdir -p /var/opt/outline/data

cat <<EOF >/opt/outline/.env
NODE_ENV=production
URL=
SECRET_KEY=$SECRET_KEY
UTILS_SECRET=$UTILS_SECRET
DATABASE_URL=$DATABASE_URL
REDIS_URL=redis://localhost:6379
FILE_STORAGE=local
FILE_STORAGE_LOCAL_ROOT_DIR=/var/opt/outline/data
FILE_STORAGE_UPLOAD_MAX_SIZE=262144000
WEB_CONCURRENCY=2
EOF

echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Outline"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/outline.service
[Unit]
Description=Outline Service
After=network.target

[Service]
Type=exec
WorkingDirectory=/opt/outline
ExecStart=/usr/bin/yarn start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now outline.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
