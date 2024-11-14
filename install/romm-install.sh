#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: SavageCore
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
# Ask the user for the required environment variables (IGDB_CLIENT_ID, IGDB_CLIENT_SECRET, MOBYGAMES_API_KEY, STEAMGRIDDB_API_KEY, ROMM_AUTH_SECRET_KEY)
IGDB_CLIENT_ID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Enter your IGDB Client ID" 8 58 --title "IGDB Client ID" 3>&1 1>&2 2>&3)
IGDB_CLIENT_SECRET=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Enter your IGDB Client Secret" 8 58 --title "IGDB Client Secret" 3>&1 1>&2 2>&3)
MOBYGAMES_API_KEY=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Enter your MobyGames API Key" 8 58 --title "MobyGames API Key" 3>&1 1>&2 2>&3)
STEAMGRIDDB_API_KEY=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Enter your SteamGridDB API Key" 8 58 --title "SteamGridDB API Key" 3>&1 1>&2 2>&3)
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
# $STD apt-get install -y sudo
# $STD apt-get install -y mc
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

msg_info "Installing Docker Compose $DOCKER_COMPOSE_LATEST_VERSION"
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -sSL https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_LATEST_VERSION/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
msg_ok "Installed Docker Compose $DOCKER_COMPOSE_LATEST_VERSION"

msg_info "Installing RomM"
mkdir -p /opt/romm{,/library,/assets,/config}
# Download the example compose.yaml file
wget -q -O /opt/romm/compose.yaml https://raw.githubusercontent.com/rommapp/romm/refs/heads/release/examples/docker-compose.example.yml

ROMM_AUTH_SECRET_KEY=$(openssl rand -hex 32)
DB_PASSWD=$(openssl rand -hex 32)
MYSQL_PASSWORD=$DB_PASSWD
MYSQL_ROOT_PASSWORD=$(openssl rand -hex 32)

# Replace the placeholders in the compose.yaml file with the user's input
sed -i "s/IGDB_CLIENT_ID=/IGDB_CLIENT_ID=$IGDB_CLIENT_ID/" /opt/romm/compose.yaml
sed -i "s/IGDB_CLIENT_SECRET=/IGDB_CLIENT_SECRET=$IGDB_CLIENT_SECRET/" /opt/romm/compose.yaml
sed -i "s/MOBYGAMES_API_KEY=/MOBYGAMES_API_KEY=$MOBYGAMES_API_KEY/" /opt/romm/compose.yaml
sed -i "s/STEAMGRIDDB_API_KEY/STEAMGRIDDB_API_KEY=$STEAMGRIDDB_API_KEY/" /opt/romm/compose.yaml
sed -i "s/ROMM_AUTH_SECRET_KEY=/ROMM_AUTH_SECRET_KEY=$ROMM_AUTH_SECRET_KEY/" /opt/romm/compose.yaml
sed -i "s/DB_PASSWD=/DB_PASSWD=$DB_PASSWD/" /opt/romm/compose.yaml
sed -i "s/MYSQL_PASSWORD=/MYSQL_PASSWORD=$MYSQL_PASSWORD/" /opt/romm/compose.yaml
sed -i "s/MYSQL_ROOT_PASSWORD=/MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD/" /opt/romm/compose.yaml

# Update the paths in the compose.yaml file to the correct paths on the host
sed -i "s|/path/to/library|/opt/romm/library|" /opt/romm/compose.yaml
sed -i "s|/path/to/assets|/opt/romm/assets|" /opt/romm/compose.yaml
sed -i "s|/path/to/config|/opt/romm/config|" /opt/romm/compose.yaml

cd /opt/romm
$STD docker compose up -d
msg_ok "Installed RomM"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
