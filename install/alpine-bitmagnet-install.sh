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

msg_info "Installing dependencies"
$STD apk add --no-cache \
  gcc \
  musl-dev \
  git \
  iproute2-ss \
  sudo
$STD apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community go
msg_ok "Installed dependencies"

msg_info "Installing PostgreSQL"
$STD apk add --no-cache \
  postgresql16 \
  postgresql16-contrib \
  postgresql16-openrc
$STD rc-update add postgresql
$STD rc-service postgresql start
msg_ok "Installed PostreSQL"

RELEASE=$(curl -fsSL https://api.github.com/repos/bitmagnet-io/bitmagnet/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')

msg_info "Installing bitmagnet v${RELEASE}"
mkdir -p /opt/bitmagnet
temp_file=$(mktemp)
curl -fsSL "https://github.com/bitmagnet-io/bitmagnet/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
tar zxf "$temp_file" --strip-components=1 -C /opt/bitmagnet
cd /opt/bitmagnet
VREL=v$RELEASE
$STD go build -ldflags "-s -w -X github.com/bitmagnet-io/bitmagnet/internal/version.GitTag=$VREL"
chmod +x bitmagnet
$STD su - postgres -c "psql -c 'CREATE DATABASE bitmagnet;'"
echo "${RELEASE}" >/opt/bitmagnet_version.txt
msg_ok "Installed bitmagnet v${RELEASE}"

read -rp "${TAB3}Enter your TMDB API key if you have one: " tmdbapikey

msg_info "Enabling bitmagnet Service"
cat <<EOF >/etc/init.d/bitmagnet
#!/sbin/openrc-run
description="bitmagnet Service"
directory="/opt/bitmagnet"
command="/opt/bitmagnet/bitmagnet"
command_args="worker run --all"
command_background="true"
command_user="root"
pidfile="/var/run/bitmagnet.pid"

depend() {
    use net
}

start_pre() {
    export TMDB_API_KEY="$tmdbapikey"
}
EOF
chmod +x /etc/init.d/bitmagnet
$STD rc-update add bitmagnet default
msg_ok "Enabled bitmagnet Service"

msg_info "Starting bitmagnet"
$STD service bitmagnet start
msg_ok "Started bitmagnet"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apk cache clean
msg_ok "Cleaned"
