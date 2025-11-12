#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/evcc-io/evcc

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setting up evcc Repository"
setup_deb822_repo \
  "evcc-stable" \
  "https://dl.evcc.io/public/evcc/stable/gpg.EAD5D0E07B0EC0FD.key" \
  "https://dl.evcc.io/public/evcc/stable/deb/debian/" \
  "$(get_os_info codename)" \
  "main"
$STD apt update
msg_ok "evcc Repository setup sucessfully"

msg_info "Installing evcc"
$STD apt install -y evcc
systemctl enable -q --now evcc
msg_ok "Installed evcc"

motd_ssh
customize
cleanup_lxc
