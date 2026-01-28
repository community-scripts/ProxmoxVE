#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://dockge.kuma.pet/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

DOCKER_LATEST_VERSION=$(get_latest_github_release "moby/moby")

msg_info "Installing Docker $DOCKER_LATEST_VERSION (with Compose, Buildx)"
DOCKER_CONFIG_PATH='/etc/docker/daemon.json'
mkdir -p $(dirname $DOCKER_CONFIG_PATH)
echo -e '{\n  "log-driver": "journald"\n}' >/etc/docker/daemon.json
$STD sh <(curl -fsSL https://get.docker.com)
msg_ok "Installed Docker $DOCKER_LATEST_VERSION"

msg_info "Installing Dockge"
mkdir -p /opt/{dockge,stacks}
curl -fsSL "https://raw.githubusercontent.com/louislam/dockge/master/compose.yaml" -o "/opt/dockge/compose.yaml"
cd /opt/dockge
$STD docker compose up -d
msg_ok "Installed Dockge"

read -r -p "${TAB3}Would you like to add Immich? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Adding Immich compose.yaml"
  mkdir -p /opt/stacks/immich
  curl -fsSL "https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml" -o "/opt/stacks/immich/compose.yaml"
  curl -fsSL "https://github.com/immich-app/immich/releases/latest/download/example.env" -o "/opt/stacks/immich/.env"
  msg_ok "Added Immich compose.yaml"
fi

read -r -p "${TAB3}Would you like to add Home Assistant? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Adding Home Assistant compose.yaml"
  mkdir -p /opt/stacks/homeassistant
  cat <<EOF >/opt/stacks/homeassistant/compose.yaml
version: "3"
services:
  homeassistant:
    container_name: homeassistant
    image: ghcr.io/home-assistant/home-assistant:stable
    volumes:
      - ./config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
    restart: unless-stopped
    privileged: true
    network_mode: host
EOF
  msg_ok "Added Home Assistant compose.yaml"
fi

motd_ssh
customize
cleanup_lxc
