#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT
# Source: Proxmox Server Solution GmbH

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    curl \
    sudo \
    gpg \
    mc 
msg_ok "Installed Dependencies"

msg_info "Installing Proxmox Datacenter Manager"
curl -fsSL https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg | gpg --dearmor -o /etc/apt/keyrings/proxmox-release-bookworm.gpg
echo "deb [signed-by=/etc/apt/keyrings/proxmox-release-bookworm.gpg] http://download.proxmox.com/debian/pdm bookworm pdm-test  " >/etc/apt/sources.list.d/proxmox-release-bookworm.list
$STD apt-get update
$STD apt-get install -y \
    proxmox-datacenter-manager \
    proxmox-datacenter-manager-ui
msg_ok "Installed Proxmox Datacenter Manager"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"