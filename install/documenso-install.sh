#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/documenso/documenso

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setup Functions"
setup_local_ip_helper
import_local_ip
msg_ok "Setup Functions"

msg_info "Installing Dependencies"
$STD apt-get install -y \
    gpg \
    libc6 \
    make \
    cmake \
    jq \
    postgresql \
    python3 \
    python3-bcrypt
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g turbo@1.9.3
msg_ok "Installed Node.js"

msg_info "Setting up PostgreSQL"
DB_NAME="documenso_db"
DB_USER="documenso_user"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC'"
{
    echo "Documenso-Credentials"
    echo "Database Name: $DB_NAME"
    echo "Database User: $DB_USER"
    echo "Database Password: $DB_PASS"
} >>~/documenso.creds
msg_ok "Set up PostgreSQL"

msg_info "Installing Documenso (Patience)"
cd /opt
RELEASE=$(curl -fsSL https://api.github.com/repos/documenso/documenso/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/documenso/documenso/archive/refs/tags/v${RELEASE}.zip"
unzip -q v${RELEASE}.zip
mv documenso-${RELEASE} /opt/documenso
cd /opt/documenso
mv .env.example /opt/documenso/.env
sed -i \
    -e "s|^NEXTAUTH_SECRET=.*|NEXTAUTH_SECRET='$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)'|" \
    -e "s|^NEXT_PRIVATE_ENCRYPTION_KEY=.*|NEXT_PRIVATE_ENCRYPTION_KEY='$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)'|" \
    -e "s|^NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY=.*|NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY='$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)'|" \
    -e "s|^DOCUMENSO_ENCRYPTION_KEY=.*|DOCUMENSO_ENCRYPTION_KEY='$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)'|" \
    -e "s|^DOCUMENSO_ENCRYPTION_SECONDARY_KEY=.*|DOCUMENSO_ENCRYPTION_SECONDARY_KEY='$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)'|" \
    -e "s|^NEXTAUTH_URL=.*|NEXTAUTH_URL=\"http://${LOCAL_IP}:3000\"|" \
    -e "s|^NEXT_PUBLIC_WEBAPP_URL=.*|NEXT_PUBLIC_WEBAPP_URL='http://${LOCAL_IP}:9000'|" \
    -e "s|^NEXT_PUBLIC_MARKETING_URL=.*|NEXT_PUBLIC_MARKETING_URL=\"http://${LOCAL_IP}:3001\"|" \
    -e "s|^NEXT_PRIVATE_INTERNAL_WEBAPP_URL=.*|NEXT_PRIVATE_INTERNAL_WEBAPP_URL=\"http://${LOCAL_IP}:3000\"|" \
    -e "s|^NEXT_PRIVATE_DATABASE_URL=.*|NEXT_PRIVATE_DATABASE_URL=\"postgres://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME\"|" \
    -e "s|^NEXT_PRIVATE_DIRECT_DATABASE_URL=.*|NEXT_PRIVATE_DIRECT_DATABASE_URL=\"postgres://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME\"|" \
    /opt/documenso/.env
export TURBO_CACHE=1
export NEXT_TELEMETRY_DISABLED=1
export CYPRESS_INSTALL_BINARY=0
export NODE_OPTIONS="--max-old-space-size=4096"
# $STD npm ci --cache ~/.npm-cache --maxsockets=5
# $STD npm run build
# $STD npx prisma migrate deploy --schema ./packages/prisma/schema.prisma
$STD npm ci
$STD npm run build:web
$STD npm run prisma:migrate-deploy
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Documenso"

msg_info "Create User"
PASSWORD_HASH=$(python3 -c "import bcrypt; print(bcrypt.hashpw(b'helper-scripts', bcrypt.gensalt(rounds=12)).decode())")
sudo -u postgres psql -d documenso_db -c "INSERT INTO \"User\" (name, email, \"emailVerified\", password, \"identityProvider\", roles, \"createdAt\", \"lastSignedIn\", \"updatedAt\", \"customerId\") VALUES ('helper-scripts', 'helper-scripts@local.com', '2025-01-20 17:14:45.058', '$PASSWORD_HASH', 'DOCUMENSO', ARRAY['USER', 'ADMIN']::\"Role\"[], '2025-01-20 16:04:05.543', '2025-01-20 16:14:55.249', '2025-01-20 16:14:55.25', NULL) RETURNING id;"
$STD npm run prisma:migrate-deploy
msg_ok "User created"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/documenso.service
[Unit]
Description=Documenso Service
After=network.target postgresql.service

[Service]
WorkingDirectory=/opt/documenso/apps/web
ExecStart=/usr/bin/npm start
Restart=always
EnvironmentFile=/opt/documenso/.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now documenso
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
