#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://umami.is/ | Github: https://github.com/umami-software/umami

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION="17" setup_postgresql
PG_DB_NAME="umamidb" PG_DB_USER="umami" setup_postgresql_db
fetch_and_deploy_gh_release "umami" "umami-software/umami" "tarball"

PNPM_VERSION=$(jq -r '.engines.pnpm // "latest"' /opt/umami/package.json)
NODE_VERSION="22" NODE_MODULE="pnpm@${PNPM_VERSION}" setup_nodejs

msg_info "Configuring Umami"
cd /opt/umami
$STD pnpm install
echo -e "DATABASE_URL=postgresql://$PG_DB_USER:$PG_DB_PASS@localhost:5432/$PG_DB_NAME" >>/opt/umami/.env
echo "APP_SECRET=$(openssl rand -hex 32)" >>/opt/umami/.env
$STD pnpm run build
msg_ok "Configured Umami"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/umami.service
[Unit]
Description=umami

[Service]
Type=simple
Restart=always
User=root
WorkingDirectory=/opt/umami
ExecStart=/usr/bin/pnpm run start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now umami
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
