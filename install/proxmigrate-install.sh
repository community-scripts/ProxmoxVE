#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: csd440
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/backupassure/proxmigrate

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y git
msg_ok "Installed Dependencies"

msg_info "Cloning ${APP} Repository"
$STD git clone https://github.com/backupassure/proxmigrate.git /opt/proxmigrate-src
msg_ok "Cloned ${APP} Repository"

msg_info "Running ${APP} Installer"
cd /opt/proxmigrate-src || exit
$STD bash install.sh
msg_ok "Installed ${APP}"

motd_ssh
customize
cleanup_lxc
