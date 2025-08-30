#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://homarr.dev/

APP="homarr"
var_tags="${var_tags:-arr;dashboard}"
var_cpu="${var_cpu:-3}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"

variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/homarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ -f /opt/homarr/database/db.sqlite ]]; then
    msg_error "Old Homarr detected due to existing database file (/opt/homarr/database/db.sqlite)."
    msg_error "Update not supported. Refer to:"
    msg_error " - https://github.com/community-scripts/ProxmoxVE/discussions/1551"
    msg_error " - https://homarr.dev/docs/getting-started/after-the-installation/#importing-a-zip-from-version-before-100"
    exit 1
  fi
  if [[ ! -f /opt/run_homarr.sh ]]; then
    msg_info "Detected outdated and missing service files"
    msg_error "Warning - The port of homarr changed from 3000 to 7575"
    $STD apt-get install -y nginx gettext openssl gpg
    sed -i '/^NODE_ENV=/d' /opt/homarr/.env && echo "NODE_ENV='production'" >>/opt/homarr/.env
    sed -i '/^DB_DIALECT=/d' /opt/homarr/.env && echo "DB_DIALECT='sqlite'" >>/opt/homarr/.env
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
    rm /etc/systemd/system/homarr.service
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
    msg_ok "Updated Services"
    systemctl daemon-reload
  fi

  if check_for_gh_release "homarr" "homarr-labs/homarr"; then
    msg_info "Stopping Services (Patience)"
    systemctl stop homarr
    msg_ok "Services Stopped"

    msg_info "Backup Data"
    mkdir -p /opt/homarr-data-backup
    cp /opt/homarr/.env /opt/homarr-data-backup/.env
    msg_ok "Backup Data"

    msg_info "Updating Nodejs"
    $STD apt update
    $STD apt upgrade nodejs -y
    msg_ok "Updated Nodejs"

    NODE_VERSION=$(curl -s https://raw.githubusercontent.com/homarr-labs/homarr/dev/package.json | jq -r '.engines.node | split(">=")[1] | split(".")[0]')
    NODE_MODULE="pnpm@$(curl -s https://raw.githubusercontent.com/homarr-labs/homarr/dev/package.json | jq -r '.packageManager | split("@")[1]')"
    setup_nodejs

    rm -rf /opt/homarr
    fetch_and_deploy_gh_release "homarr" "homarr-labs/homarr"

    msg_info "Updating and rebuilding ${APP} (Patience)"
    rm /opt/run_homarr.sh
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
    mv /opt/homarr-data-backup/.env /opt/homarr/.env
    cd /opt/homarr
    $STD pnpm install --recursive --frozen-lockfile --shamefully-hoist
    $STD pnpm build
    cp /opt/homarr/apps/nextjs/next.config.ts .
    cp /opt/homarr/apps/nextjs/package.json .
    cp -r /opt/homarr/packages/db/migrations /opt/homarr_db/migrations
    cp -r /opt/homarr/apps/nextjs/.next/standalone/* /opt/homarr
    mkdir -p /appdata/redis
    cp /opt/homarr/packages/redis/redis.conf /opt/homarr/redis.conf
    rm /etc/nginx/nginx.conf
    mkdir -p /etc/nginx/templates
    cp /opt/homarr/nginx.conf /etc/nginx/templates/nginx.conf

    mkdir -p /opt/homarr/apps/cli
    cp /opt/homarr/packages/cli/cli.cjs /opt/homarr/apps/cli/cli.cjs
    echo $'#!/bin/bash\ncd /opt/homarr/apps/cli && node ./cli.cjs "$@"' >/usr/bin/homarr
    chmod +x /usr/bin/homarr

    mkdir /opt/homarr/build
    cp ./node_modules/better-sqlite3/build/Release/better_sqlite3.node ./build/better_sqlite3.node
    msg_ok "Updated ${APP}"

    msg_info "Starting Services"
    systemctl start homarr
    msg_ok "Started Services"
    msg_ok "Updated Successfully"
    read -p "${TAB3}It's recommended to reboot the LXC after an update, would you like to reboot the LXC now ? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
      reboot
    fi
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7575${CL}"
