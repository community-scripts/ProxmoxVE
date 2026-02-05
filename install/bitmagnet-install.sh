#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bitmagnet-io/bitmagnet

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  iproute2 \
  gcc \
  musl-dev
msg_ok "Installed Dependencies"

PG_VERSION="16" setup_postgresql
PG_DB_NAME="bitmagnet" PG_DB_USER="bitmagnet" setup_postgresql_db
setup_go

fetch_and_deploy_gh_release "bitmagnet" "bitmagnet-io/bitmagnet" "tarball"
RELEASE=$(cat ~/.bitmagnet)

msg_info "Configuring bitmagnet"
cd /opt/bitmagnet
$STD go build -ldflags "-s -w -X github.com/bitmagnet-io/bitmagnet/internal/version.GitTag=v${RELEASE}"
chmod +x bitmagnet
msg_ok "Configured bitmagnet"

read -r -p "${TAB3}Enter your TMDB API key if you have one: " tmdbapikey

cat <<EOF >/etc/bitmagnet.env
POSTGRES_HOST=localhost
POSTGRES_USER=${PG_DB_USER}
POSTGRES_NAME=${PG_DB_NAME}
POSTGRES_PASSWORD=${PG_DB_PASS}
EOF

if [ -z "$tmdbapikey" ]; then
  echo "TMDB_ENABLED=false" >>/etc/bitmagnet.env
else
  echo "TMDB_API_KEY=$tmdbapikey" >>/etc/bitmagnet.env
fi

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/bitmagnet-web.service
[Unit]
Description=bitmagnet Web GUI
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/bitmagnet
EnvironmentFile=/etc/bitmagnet.env
ExecStart=/opt/bitmagnet/bitmagnet worker run --all
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now bitmagnet-web
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
