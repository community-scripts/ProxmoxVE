#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: CrazyWolf13
# License: MIT
# Source: https://forum.proxmox.com/threads/proxmox-datacenter-manager-first-alpha-release.159323/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl \
    sudo \
    mc 
msg_ok "Installed Dependencies"

msg_info "Installing Proxmox Backup Server"
wget -q https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
cat <<EOF >>/etc/apt/sources.list
deb http://download.proxmox.com/debian/pdm bookworm pdm-test
EOF
$STD apt-get update
$STD apt-get install -y proxmox-datacenter-manager \
    proxmox-datacenter-manager-ui
msg_ok "Installed Proxmox Backup Server"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"