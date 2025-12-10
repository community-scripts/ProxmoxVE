#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://umami.is/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs
PG_VERSION="17" setup_postgresql
PG_DB_NAME="umamidb" PG_DB_USER="umami" setup_postgresql_db
fetch_and_deploy_gh_release "umami" "umami-software/umami" "tarball"

msg_info "Configuring Umami"
cd /opt/umami
$STD yarn install
echo -e "DATABASE_URL=postgresql://$PG_DB_USER:$PG_DB_PASS@localhost:5432/$PG_DB_NAME" >>/opt/umami/.env
$STD yarn run build
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
ExecStart=/usr/bin/yarn run start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now umami
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
