#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

get_latest_release() {
  curl -sL https://api.github.com/repos/$1/releases/latest | grep '"tag_name":' | cut -d'"' -f4
}

DOCKER_LATEST_VERSION=$(get_latest_release "moby/moby")
DOCKER_COMPOSE_LATEST_VERSION=$(get_latest_release "docker/compose")

msg_info "Installing Docker $DOCKER_LATEST_VERSION"
DOCKER_CONFIG_PATH='/etc/docker/daemon.json'
mkdir -p $(dirname $DOCKER_CONFIG_PATH)
echo -e '{\n  "log-driver": "journald"\n}' >/etc/docker/daemon.json
$STD sh <(curl -sSL https://get.docker.com)
msg_ok "Installed Docker $DOCKER_LATEST_VERSION"


msg_ok "Installing Latest SnipeIT Docker\n"

mkdir /opt/snipeit
cd /opt/snipeit
$STD curl https://raw.githubusercontent.com/snipe/snipe-it/master/docker-compose.yml --output docker-compose.yml
$STD curl https://raw.githubusercontent.com/snipe/snipe-it/master/.env.docker --output .env
msg_info "Setting the APP_URL to the current IP address: $IPADDRESS"
IPADDRESS=$(hostname -I | awk '{print $1}')
sed -i "s|^APP_URL=.*|APP_URL=http://$IPADDRESS:8000|" .env

msg_ok "Generating APP_KEY\n"

docker compose run --rm app php artisan key:generate --show

msg_info "Starting docker container"

$STD docker compose up -d

msg_ok "Installed SnipeIT, you can reach it under http://$IPADDRESS:8000"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
