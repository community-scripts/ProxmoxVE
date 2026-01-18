#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docmost.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  redis \
  make
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="pnpm@$(curl -s https://raw.githubusercontent.com/docmost/docmost/main/package.json | jq -r '.packageManager | split("@")[1]')" setup_nodejs
PG_VERSION="16" setup_postgresql
PG_DB_NAME="docmost_db" PG_DB_USER="docmost_user" setup_postgresql_db
import_local_ip
fetch_and_deploy_gh_release "docmost" "docmost/docmost" "tarball"

msg_info "Configuring Docmost (Patience)"
cd /opt/docmost
mv .env.example .env
mkdir data
sed -i -e "s|APP_SECRET=.*|APP_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)|" \
  -e "s|DATABASE_URL=.*|DATABASE_URL=\"postgres://$PG_DB_USER:$PG_DB_PASS@localhost:5432/$PG_DB_NAME?schema=public\"|" \
  -e "s|FILE_UPLOAD_SIZE_LIMIT=.*|FILE_UPLOAD_SIZE_LIMIT=50mb|" \
  -e "s|DRAWIO_URL=.*|DRAWIO_URL=https://embed.diagrams.net|" \
  -e "s|DISABLE_TELEMETRY=.*|DISABLE_TELEMETRY=true|" \
  -e "s|APP_URL=.*|APP_URL=http://$LOCAL_IP:3000|" \
  /opt/docmost/.env
export NODE_OPTIONS="--max-old-space-size=2048"
$STD pnpm install
$STD pnpm build
msg_ok "Configured Docmost"

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
cleanup_lxc
