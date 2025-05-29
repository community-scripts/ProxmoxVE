#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apk add ca-certificates
$STD update-ca-certificates
msg_ok "Installed Dependencies"

msg_info "Installing Traefik"
$STD apk add traefik --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
msg_ok "Installed Traefik"

read -p "${TAB3}Enable Traefik WebUI (Port 8080)? [y/N]: " enable_webui
if [[ "$enable_webui" =~ ^[Yy]$ ]]; then
  msg_info "Configuring Traefik WebUI"
  sed -i 's/localhost//g' /etc/traefik/traefik.yaml
  msg_ok "Configured Traefik WebUI"
fi

msg_info "Enabling and starting Traefik service"
$STD rc-update add traefik default
sed -i '/^command=.*/i directory="/etc/traefik"' /etc/init.d/traefik
$STD rc-service traefik start
msg_ok "Traefik service started"

motd_ssh
customize
