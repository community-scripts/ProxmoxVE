#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://listmonk.app/ | Github: https://github.com/knadh/listmonk

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION="17" setup_postgresql

PG_DB_NAME="listmonk" PG_DB_USER="listmonk" setup_postgresql_db

fetch_and_deploy_gh_release "listmonk" "knadh/listmonk" "prebuild" "latest" "/opt/listmonk" "listmonk*linux_$(arch_resolve).tar.gz"

msg_info "Configuring listmonk"
mkdir -p /opt/listmonk/uploads
$STD /opt/listmonk/listmonk --new-config --config /opt/listmonk/config.toml
sed -i -e 's/address = "localhost:9000"/address = "0.0.0.0:9000"/' -e 's/^password = ".*"/password = "'"$PG_DB_PASS"'"/' /opt/listmonk/config.toml
$STD /opt/listmonk/listmonk --install --yes --config /opt/listmonk/config.toml
msg_ok "Configured listmonk"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/listmonk.service
[Unit]
Description=Listmonk Service
Wants=network.target
After=postgresql.service

[Service]
Type=simple
ExecStart=/opt/listmonk/listmonk --config /opt/listmonk/config.toml
Restart=always
RestartSec=3
WorkingDirectory=/opt/listmonk

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now listmonk
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
