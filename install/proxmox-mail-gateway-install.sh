#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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
setup_deb822_repo \
  "pmg" \
  "https://enterprise.proxmox.com/debian/proxmox-release-trixie.gpg" \
  "http://download.proxmox.com/debian/pmg" \
  "trixie" \
  "pmg-no-subscription"
$STD apt install -y proxmox-mailgateway-container
msg_ok "Installed Proxmox Mail Gateway"

motd_ssh
customize
cleanup_lxc
