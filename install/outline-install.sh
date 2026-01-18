#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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
$STD apt install -y \
  mkcert \
  git \
  redis
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
PG_VERSION="16" setup_postgresql
PG_DB_NAME="outline" PG_DB_USER="outline" setup_postgresql_db
fetch_and_deploy_gh_release "outline" "outline/outline" "tarball"
import_local_ip

msg_info "Configuring Outline (Patience)"
SECRET_KEY="$(openssl rand -hex 32)"
cd /opt/outline
cp .env.sample .env
export NODE_ENV=development
sed -i 's/NODE_ENV=production/NODE_ENV=development/g' /opt/outline/.env
sed -i "s/generate_a_new_key/${SECRET_KEY}/g" /opt/outline/.env
sed -i "s/user:pass@postgres/${PG_DB_USER}:${PG_DB_PASS}@localhost/g" /opt/outline/.env
sed -i 's/redis:6379/localhost:6379/g' /opt/outline/.env
sed -i "5s#URL=#URL=http://${LOCAL_IP}#g" /opt/outline/.env
sed -i 's/FORCE_HTTPS=true/FORCE_HTTPS=false/g' /opt/outline/.env
export NODE_OPTIONS="--max-old-space-size=3584"
$STD corepack enable
$STD yarn install --immutable
export NODE_ENV=production
sed -i 's/NODE_ENV=development/NODE_ENV=production/g' /opt/outline/.env
$STD yarn build
msg_ok "Configured Outline"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/outline.service
[Unit]
Description=Outline Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/outline
ExecStart=/usr/bin/yarn start
Restart=always
EnvironmentFile=/opt/outline/.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now outline
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
