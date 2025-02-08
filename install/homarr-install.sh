#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ajnart/homarr

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
  redis-server \
  ca-certificates \
  gnupg \
  make \
  g++ \
  build-essential \
  nginx \
  gettext \
  openssl
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js/pnpm"
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g pnpm@latest
msg_ok "Installed Node.js/pnpm"

msg_info "Installing Homarr (Patience)"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/homarr-labs/homarr/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/homarr-labs/homarr/archive/refs/tags/v${RELEASE}.zip"
unzip -q v${RELEASE}.zip
mv homarr-${RELEASE} /opt/homarr
mkdir -p /opt/homarr_db
touch /opt/homarr_db/db.sqlite
AUTH_SECRET="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
SECRET_ENCRYPTION_KEY="$(openssl rand -hex 32)"

cat <<EOF >/opt/homarr/.env
AUTH_SECRET='${AUTH_SECRET}'
DB_DRIVER='better-sqlite3'
DB_DIALECT='sqlite'
SECRET_ENCRYPTION_KEY='${SECRET_ENCRYPTION_KEY}'
DB_URL='/opt/homarr_db/db.sqlite'
TURBO_TELEMETRY_DISABLED=1
AUTH_PROVIDERS='credentials'
NODE_ENV='production'
EOF

cd /opt/homarr

$STD pnpm install
cd /opt/homarr/apps/nextjs
$STD pnpm build
mkdir build

cp /opt/homarr/apps/nextjs/next.config.ts .
cp /opt/homarr/apps/nextjs/package.json .

cp -r /opt/homarr/packages/db/migrations /opt/homarr_db/migrations
cp -r /opt/homarr/apps/nextjs/.next/standalone/* /opt/homarr



# Copy Redis and Nginx configurations from repository
cp /opt/homarr/packages/redis/redis.conf /app/packages/redis/redis.conf
cp /opt/homarr/nginx.conf /etc/nginx/templates/nginx.conf

# Enable homar-cli
cp /opt/homarr/packages/cli/cli.cjs /opt/homarr/apps/cli/cli.cjs
echo $'#!/bin/bash\ncd /opt/homarr/apps/cli && node ./cli.cjs "$@"' > /usr/bin/homarr
chmod +x /usr/bin/homarr

cp ./node_modules/better-sqlite3/build/Release/better_sqlite3.node ./build/better_sqlite3.node
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Homarr"

msg_info "Creating Services"
{
  # Run migrations
  DB_DIALECT='sqlite'
  node /opt/homarr_db/migrations/$DB_DIALECT/migrate.cjs /opt/homarr_db/migrations/$DB_DIALECT
  # Auth secret is generated every time the container starts as it is required, but not used because we don't need JWTs or Mail hashing
  export AUTH_SECRET=$(openssl rand -base64 32)
  envsubst ${HOSTNAME} < /etc/nginx/templates/nginx.conf > /etc/nginx/nginx.conf
  nginx -g 'daemon off;' &
  # Start nginx proxy
  # 1. Replace the HOSTNAME in the nginx template file
  # 2. Create the nginx configuration file from the template
  # 3. Start the nginx server
  redis-server /opt/homarr/packages/redis/redis.conf &
  # Run the tasks backend
  node apps/tasks/tasks.cjs &
  node apps/websocket/wssServer.cjs &
  # Run the nextjs server
  node apps/nextjs/server.js & PID=$!
  wait $PID
} > /opt/run_homarr.sh 2>&1 &
chmod +x /opt/run_homarr.sh

cat <<EOF >/etc/systemd/system/homarr.service
[Unit]
Description=Homarr Service
After=network.target

[Service]
Type=exec
WorkingDirectory=/opt/homarr
EnvironmentFile=-/opt/homarr/.env
ExecStart=/opt/run_homarr.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now homarr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
