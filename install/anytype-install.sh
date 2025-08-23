#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Jeron Wong (ThisIsJeron)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/anyproto/any-sync-dockercompose

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

get_latest_release() {
  curl -fsSL https://api.github.com/repos/$1/releases/latest | grep '"tag_name":' | cut -d '"' -f4
}

RELEASE=$(get_latest_release "anyproto/any-sync-dockercompose")

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git \
  make \
  jq
msg_ok "Installed Dependencies"

msg_info "Installing Docker"
DOCKER_CONFIG_PATH='/etc/docker/daemon.json'
mkdir -p $(dirname $DOCKER_CONFIG_PATH)
echo -e '{\n  "log-driver": "journald"\n}' >/etc/docker/daemon.json
$STD sh <(curl -fsSL https://get.docker.com)
systemctl enable -q --now docker
msg_ok "Installed Docker"

msg_info "Installing Docker Compose plugin"
mkdir -p /usr/local/lib/docker/cli-plugins
COMPOSE_VER=$(get_latest_release "docker/compose")
curl -fsSL "https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
msg_ok "Installed Docker Compose ${COMPOSE_VER}"

msg_info "Deploying Anytype any-sync ${RELEASE}"
git clone --depth 1 --branch "${RELEASE}" https://github.com/anyproto/any-sync-dockercompose.git /opt/anytype
cd /opt/anytype
echo "EXTERNAL_LISTEN_HOSTS=${IP}" >> .env.override
make start
echo "${RELEASE#v}" >/opt/anytype_version.txt
msg_ok "Deployed Anytype any-sync"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
