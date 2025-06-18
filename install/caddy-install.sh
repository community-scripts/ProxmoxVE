#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://caddyserver.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  debian-keyring \
  debian-archive-keyring \
  apt-transport-https
msg_ok "Installed Dependencies"

msg_info "Installing Caddy"
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' >/etc/apt/sources.list.d/caddy-stable.list
$STD apt-get update
$STD apt-get install -y caddy
msg_ok "Installed Caddy"

read -r -p "${TAB3}Would you like to install xCaddy Addon? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  setup_go
  msg_info "Setup xCaddy"
  $STD apt-get install -y git
  cd /opt
  RELEASE=$(curl -fsSL https://api.github.com/repos/caddyserver/xcaddy/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  curl -fsSL "https://github.com/caddyserver/xcaddy/releases/download/${RELEASE}/xcaddy_${RELEASE:1}_linux_amd64.deb" -o "xcaddy_${RELEASE:1}_linux_amd64.deb"
  $STD dpkg -i xcaddy_"${RELEASE:1}"_linux_amd64.deb
  rm -rf /opt/xcaddy*
  $STD xcaddy build
  msg_ok "Setup xCaddy"
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
