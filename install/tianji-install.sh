#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/msgbyte/tianji

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  postgresql \
  python3 \
  cmake \
  g++ \
  build-essential \
  curl \
  sudo \
  git \
  make \
  gnupg \
  ca-certificates \
  mc
msg_ok "Installed Dependencies"

msg_info "Installing Node.js"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g pnpm@9.7.1
export NODE_OPTIONS="--max_old_space_size=4096"
msg_ok "Installed Node.js"

msg_info "Setting up PostgreSQL"
DB_NAME=tianji_db
DB_USER=tianji
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
TIANJI_SECRET="$(openssl rand -base64 32 | cut -c1-24)"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" 
$STD sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
$STD sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
echo "" >>~/tianji.creds
echo -e "Tianji Database User: $DB_USER" >>~/tianji.creds
echo -e "Tianji Database Password: $DB_PASS" >>~/tianji.creds
echo -e "Tianji Database Name: $DB_NAME" >>~/tianji.creds
echo -e "Tianji Secret: $TIANJI_SECRET" >>~/tianji.creds
msg_ok "Set up PostgreSQL"

msg_info "Installing Tianji (Extreme Patience)"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/msgbyte/tianji/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/msgbyte/tianji/archive/refs/tags/v${RELEASE}.zip"
unzip -q v${RELEASE}.zip
mv tianji-${RELEASE} /opt/tianji
cd tianji
$STD pnpm install --filter @tianji/client... --config.dedupe-peer-dependents=false --frozen-lockfile
$STD pnpm build:static
$STD pnpm install --filter @tianji/server... --config.dedupe-peer-dependents=false
mkdir -p ./src/server/public
cp -r ./geo ./src/server/public
$STD pnpm build:server
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
cat <<EOF >/opt/tianji/src/server/.env
DATABASE_URL="postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME?schema=public"
JWT_SECRET="$TIANJI_SECRET"
EOF
cd /opt/tianji/src/server
$STD pnpm db:migrate:apply
msg_ok "Installed Tianji"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/tianji.service
[Unit]
Description=Tianji Server
After=network.target

[Service]
ExecStart=/usr/bin/node /opt/tianji/src/server/dist/src/server/main.js
WorkingDirectory=/opt/tianji/src/server
Restart=always
RestartSec=10

Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tianji.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -R /opt/v${RELEASE}.zip
rm -rf /opt/tianji/src/client
rm -rf /opt/tianji/website
rm -rf /opt/tianji/reporter
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
