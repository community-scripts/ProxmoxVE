#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install  --yes --force-yes -y curl
$STD apt-get install --yes --force-yes -y sudo
$STD apt-get install --yes --force-yes -y gpg
$STD apt-get install --yes --force-yes -y mc
msg_ok "Installed Dependencies"

msg_info "Installing Docker"
cd /tmp
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh
msg_ok "Installed Docker"

msg_info "Downloading Docker Compose Files"
cd /opt
mkdir ./immich-app
cd ./immich-app
wget -O hwaccel.ml.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.ml.yml
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
wget -O hwaccel.transcoding.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml
msg_ok "Downloaded Docker Compose Files"

sed -i "s|# extends:|extends:|" docker-compose.yml
sed -i "s|#   file: hwaccel.ml.yml|  file: hwaccel.ml.yml|" docker-compose.yml
sed -i "s|#   file: hwaccel.transcoding.yml|  file: hwaccel.transcoding.yml|" docker-compose.yml
sed -i "s|#   service: cpu # set to one of \[nvenc, quicksync, rkmpp, vaapi, vaapi-wsl\]|  service: cpu # set to one of \[nvenc, quicksync, rkmpp, vaapi, vaapi-wsl\]|" docker-compose.yml
sed -i "s|#   service: cpu # set to one of \[armnn, cuda, openvino, openvino-wsl\]|  service: cpu # set to one of \[armnn, cuda, openvino, openvino-wsl\]|" docker-compose.yml
msg_ok "Updated Config"
msg_info "Starting Containers"
sudo docker compose up -d
msg_ok "Started Containers"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
$STD docker image prune -f
msg_ok "Cleaned up"
