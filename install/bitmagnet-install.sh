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

setup_deb_based() {
  msg_info "Installing Dependencies"
  $STD apt install -y \
    iproute2 \
    gcc \
    musl-dev
  msg_ok "Installed Dependencies"

  PG_VERSION="16" setup_postgresql
  PG_DB_NAME="bitmagnet" PG_DB_USER="bitmagnet" setup_postgresql_db

  fetch_and_deploy_gh_release "bitmagnet" "bitmagnet-io/bitmagnet" "tarball"
  GO_VERSION="$(grep -m1 '^go ' /opt/bitmagnet/go.mod | awk '{print $2}')" setup_go
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
}

setup_alpine() {
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

  rm -f "$temp_file"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
