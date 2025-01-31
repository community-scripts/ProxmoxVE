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
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

msg_info "Installing Podman"
$STD apt-get -y install podman
$STD systemctl enable --now podman.socket
msg_ok "Installed Podman"

msg_info "Pulling Home Assistant Image"
$STD podman pull docker.io/homeassistant/home-assistant:stable
msg_ok "Pulled Home Assistant Image"

msg_info "Installing Home Assistant"
$STD podman volume create hass_config
$STD podman run -d \
  --name homeassistant \
  --restart unless-stopped \
  -v /dev:/dev \
  -v hass_config:/config \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  --net=host \
  homeassistant/home-assistant:stable
podman generate systemd \
  --new --name homeassistant \
  >/etc/systemd/system/homeassistant.service
$STD systemctl enable --now homeassistant
msg_ok "Installed Home Assistant"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
