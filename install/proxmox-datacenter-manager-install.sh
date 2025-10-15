#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: Proxmox Server Solution GmbH

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Proxmox Datacenter Manager"
curl -fsSL https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg -o /usr/share/keyrings/proxmox-archive-keyring.gpg
cat <<EOF >/etc/apt/sources.list.d/pdm-test.sources
Types: deb
URIs: http://download.proxmox.com/debian/pdm
Suites: trixie
Components: pdm-test
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
$STD apt update
DEBIAN_FRONTEND=noninteractive
$STD apt -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        install -y proxmox-datacenter-manager \
        proxmox-datacenter-manager-ui
msg_ok "Installed Proxmox Datacenter Manager"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
