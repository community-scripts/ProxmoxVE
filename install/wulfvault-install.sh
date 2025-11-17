#!/usr/bin/env bash

# Copyright (c) 2024-2025 community-scripts ORG
# Author: Ulf Holmström (Frimurare)
# License: MIT
# Source: https://github.com/Frimurare/WulfVault

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl sudo mc git
msg_ok "Installed Dependencies"

msg_info "Installing Docker"
$STD bash <(curl -fsSL https://get.docker.com)
msg_ok "Installed Docker"

msg_info "Installing Docker Compose"
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
LATEST=$(curl -sL https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
$STD curl -sSL https://github.com/docker/compose/releases/download/$LATEST/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
msg_ok "Installed Docker Compose"

msg_info "Setting Up WulfVault"
mkdir -p /opt/wulfvault
cd /opt/wulfvault

cat <<'EOF' > docker-compose.yml
version: '3.8'
services:
  wulfvault:
    image: frimurare/wulfvault:latest
    container_name: wulfvault
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
      - ./uploads:/uploads
    environment:
      - SERVER_URL=http://localhost:8080
      - PORT=8080
      - MAX_FILE_SIZE_MB=5000
      - DEFAULT_QUOTA_MB=10000
      - SESSION_TIMEOUT_HOURS=24
      - TRASH_RETENTION_DAYS=5
    restart: unless-stopped
EOF

mkdir -p data uploads
msg_ok "Set Up WulfVault"

msg_info "Starting WulfVault"
$STD docker compose up -d
msg_ok "Started WulfVault"

motd_ssh
customize

msg_info "Cleaning Up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
