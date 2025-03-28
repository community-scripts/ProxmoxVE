#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: thost96 (thost96)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.proxmox.com/en/products/proxmox-mail-gateway

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Proxmox Mail Gateway"
curl -fsSL "https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg" -o "/etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg"
echo "deb http://download.proxmox.com/debian/pmg bookworm pmg-no-subscription" >/etc/apt/sources.list.d/pmg.list
$STD apt-get update
$STD apt-get -y install proxmox-mailgateway-container
msg_ok "Installed Proxmox Mail Gateway"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
