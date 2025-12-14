#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/diced/zipline

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" NODE_MODULE="pnpm" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_NAME="ziplinedb" PG_DB_USER="zipline" setup_postgresql_db
fetch_and_deploy_gh_release "zipline" "diced/zipline" "tarball"
SECRET_KEY="$(openssl rand -base64 42 | tr -dc 'a-zA-Z0-9')"
echo "Zipline Secret Key: ${SECRET_KEY}" >>~/zipline.creds

msg_info "Installing Zipline (Patience)"
cd /opt/zipline || exit
cat <<EOF >/opt/zipline/.env
DATABASE_URL=postgres://$PG_DB_USER:$PG_DB_PASS@localhost:5432/$PG_DB_NAME
CORE_SECRET=$SECRET_KEY
CORE_HOSTNAME=0.0.0.0
CORE_PORT=3000
CORE_RETURN_HTTPS=false
DATASOURCE_TYPE=local
DATASOURCE_LOCAL_DIRECTORY=/opt/zipline-uploads
EOF
mkdir -p /opt/zipline-uploads
$STD pnpm install
$STD pnpm build
msg_ok "Installed Zipline"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/zipline.service
[Unit]
Description=Zipline Service
After=network.target

[Service]
WorkingDirectory=/opt/zipline
ExecStart=/usr/bin/pnpm start
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now zipline
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
