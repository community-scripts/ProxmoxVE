#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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
$STD apt-get install -y \
  iproute2 \
  gcc \
  musl-dev
msg_ok "Installed Dependencies"

PG_VERSION="16" install_postgresql
install_go
RELEASE=$(curl -s https://api.github.com/repos/bitmagnet-io/bitmagnet/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')

msg_info "Installing bitmagnet v${RELEASE}"
mkdir -p /opt/bitmagnet
temp_file=$(mktemp)
curl -fsSL "https://github.com/bitmagnet-io/bitmagnet/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
tar zxf "$temp_file" --strip-components=1 -C /opt/bitmagnet
cd /opt/bitmagnet
VREL=v$RELEASE
$STD go build -ldflags "-s -w -X github.com/bitmagnet-io/bitmagnet/internal/version.GitTag=$VREL"
chmod +x bitmagnet
POSTGRES_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$POSTGRES_PASSWORD';"
$STD sudo -u postgres psql -c "CREATE DATABASE bitmagnet;"
{
  echo "PostgreSQL Credentials"
  echo ""
  echo "postgres user password: $POSTGRES_PASSWORD"
} >>~/postgres.creds
echo "${RELEASE}" >/opt/bitmagnet_version.txt
msg_ok "Installed bitmagnet v${RELEASE}"

read -r -p "${TAB3}Enter your TMDB API key if you have one: " tmdbapikey

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/bitmagnet-web.service
[Unit]
Description=bitmagnet Web GUI
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/bitmagnet
ExecStart=/opt/bitmagnet/bitmagnet worker run --all
Environment=POSTGRES_HOST=localhost
Environment=POSTGRES_PASSWORD=$POSTGRES_PASSWORD
Environment=TMDB_API_KEY=$tmdbapikey
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now bitmagnet-web
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
