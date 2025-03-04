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
  apt-transport-https \
  gpg \
  curl \
  sudo \
  mc
msg_ok "Installed Dependencies"

msg_info "Installing Caddy"
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' >/etc/apt/sources.list.d/caddy-stable.list
$STD apt-get update
$STD apt-get install -y caddy
msg_ok "Installed Caddy"

read -r -p "Would you like to install xCaddy Addon? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  msg_info "Installing Golang"
  set +o pipefail
  temp_file=$(mktemp)
  golang_tarball=$(curl -s https://go.dev/dl/ | grep -oP 'go[\d\.]+\.linux-amd64\.tar\.gz' | head -n 1)
  wget -q https://golang.org/dl/"$golang_tarball" -O "$temp_file"
  tar -C /usr/local -xzf "$temp_file"
  ln -sf /usr/local/go/bin/go /usr/local/bin/go
  rm -f "$temp_file"
  set -o pipefail
  msg_ok "Installed Golang"

  msg_info "Setup xCaddy"
  cd /opt
  RELEASE=$(curl -s https://api.github.com/repos/caddyserver/xcaddy/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  wget -q https://github.com/caddyserver/xcaddy/releases/download/${RELEASE}/xcaddy_${RELEASE:1}_linux_amd64.deb
  $STD dpkg -i xcaddy_${RELEASE:1}_linux_amd64.deb
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
