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
curl -fsSL "https://enterprise.proxmox.com/debian/proxmox-release-trixie.gpg" -o "/usr/share/keyrings/proxmox-release-trixie.gpg"
cat <<EOF >/etc/apt/sources.list.d/pmg.sources
Types: deb
URIs: http://download.proxmox.com/debian/pmg
Suites: trixie
Components: pmg-no-subscription
Signed-By: /usr/share/keyrings/proxmox-release-trixie.gpg
EOF
$STD apt update
$STD apt -y install proxmox-mailgateway-container
msg_ok "Installed Proxmox Mail Gateway"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
