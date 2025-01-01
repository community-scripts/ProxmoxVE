#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/evcc-io/evcc

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
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
  mc \
  lsb-release \
  gpg 
msg_ok "Installed Dependencies"

msg_info "Setting up evcc Repository"
curl -fsSL https://dl.evcc.io/public/evcc/stable/gpg.EAD5D0E07B0EC0FD.key | gpg --dearmor -o /etc/apt/keyrings/evcc-stable.gpg 
echo "deb [signed-by=/etc/apt/keyrings/evcc-stable.gpg] https://dl.evcc.io/public/evcc/stable/deb/debian $(lsb_release -cs) main" >/etc/apt/sources.list.d/evcc-stable.list 
$STD apt update
msg_ok "evcc Repository setup sucessfully"

msg_info "Installing evcc"
$STD apt install -y evcc
systemctl enable -q --now evcc.service
msg_ok "Installed evcc"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
