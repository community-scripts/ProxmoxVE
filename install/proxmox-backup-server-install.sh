#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.proxmox.com/en/proxmox-backup-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Proxmox Backup Server"
curl -fsSL "https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg" -o "/etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg"
cat <<EOF >>/etc/apt/sources.list
deb http://download.proxmox.com/debian/pbs bookworm pbs-no-subscription
EOF
$STD apt-get update
export DEBIAN_FRONTEND=noninteractive
export IFUPDOWN2_NO_IFRELOAD=1
$STD apt-get install -y proxmox-backup-server
msg_ok "Installed Proxmox Backup Server"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
