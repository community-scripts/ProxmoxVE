#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MrYadro
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y git
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

msg_info "Installing Recyclarr"
wget -q $(curl -s https://api.github.com/repos/recyclarr/recyclarr/releases/latest | grep download | grep linux-x64 | cut -d\" -f4)
tar -C /usr/local/bin -xJf recyclarr*.tar.xz
mkdir -p /root/.config/recyclarr
recyclarr config create
msg_ok "Installed Recyclarr"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf recyclarr*.tar.xz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
