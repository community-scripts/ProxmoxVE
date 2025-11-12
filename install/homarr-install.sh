#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/homarr-labs/homarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  redis-server \
  ca-certificates \
  make \
  g++ \
  build-essential \
  nginx \
  gettext \
  jq \
  openssl
msg_ok "Installed Dependencies"

NODE_VERSION=$(curl -s https://raw.githubusercontent.com/homarr-labs/homarr/dev/package.json | jq -r '.engines.node | split(">=")[1] | split(".")[0]')
NODE_MODULE="pnpm@$(curl -s https://raw.githubusercontent.com/homarr-labs/homarr/dev/package.json | jq -r '.packageManager | split("@")[1]')"
setup_nodejs
fetch_and_deploy_gh_release "homarr" "homarr-labs/homarr"

msg_info "Installing Homarr (Patience)"
cd /opt
mkdir -p /opt/homarr_db
touch /opt/homarr_db/db.sqlite
SECRET_ENCRYPTION_KEY="$(openssl rand -hex 32)"
cd /opt/homarr
cat <<EOF >/opt/homarr/.env
DB_DRIVER='better-sqlite3'
DB_DIALECT='sqlite'
SECRET_ENCRYPTION_KEY='${SECRET_ENCRYPTION_KEY}'
DB_URL='/opt/homarr_db/db.sqlite'
TURBO_TELEMETRY_DISABLED=1
AUTH_PROVIDERS='credentials'
NODE_ENV='production'
EOF
$STD pnpm install --recursive --frozen-lockfile --shamefully-hoist
$STD pnpm build
msg_ok "Installed Homarr"

msg_info "Copying build and config files"
cp /opt/homarr/apps/nextjs/next.config.ts .
cp /opt/homarr/apps/nextjs/package.json .
cp -r /opt/homarr/packages/db/migrations /opt/homarr_db/migrations
cp -r /opt/homarr/apps/nextjs/.next/standalone/* /opt/homarr
mkdir -p /appdata/redis
cp /opt/homarr/packages/redis/redis.conf /opt/homarr/redis.conf
mkdir -p /etc/nginx/templates
rm /etc/nginx/nginx.conf
cp /opt/homarr/nginx.conf /etc/nginx/templates/nginx.conf
mkdir -p /opt/homarr/apps/cli
cp /opt/homarr/packages/cli/cli.cjs /opt/homarr/apps/cli/cli.cjs
echo $'#!/bin/bash\ncd /opt/homarr/apps/cli && node ./cli.cjs "$@"' >/usr/bin/homarr
chmod +x /usr/bin/homarr
mkdir /opt/homarr/build
cp ./node_modules/better-sqlite3/build/Release/better_sqlite3.node ./build/better_sqlite3.node
msg_ok "Finished copying"

msg_info "Creating Services"
cat <<'EOF' >/opt/run_homarr.sh
#!/bin/bash
set -a
source /opt/homarr/.env
set +a
export DB_DIALECT='sqlite'
export AUTH_SECRET=$(openssl rand -base64 32)
export CRON_JOB_API_KEY=$(openssl rand -base64 32)
node /opt/homarr_db/migrations/$DB_DIALECT/migrate.cjs /opt/homarr_db/migrations/$DB_DIALECT
for dir in $(find /opt/homarr_db/migrations/migrations -mindepth 1 -maxdepth 1 -type d); do
  dirname=$(basename "$dir")
  mkdir -p "/opt/homarr_db/migrations/$dirname"
  cp -r "$dir"/* "/opt/homarr_db/migrations/$dirname/" 2>/dev/null || true
done
export HOSTNAME=$(ip route get 1.1.1.1 | grep -oP 'src \K[^ ]+')
envsubst '${HOSTNAME}' < /etc/nginx/templates/nginx.conf > /etc/nginx/nginx.conf
nginx -g 'daemon off;' &
redis-server /opt/homarr/packages/redis/redis.conf &
node apps/tasks/tasks.cjs &
node apps/websocket/wssServer.cjs &
node apps/nextjs/server.js & PID=$!
wait $PID
EOF
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
cleanup_lxc
