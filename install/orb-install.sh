#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: angusmaul
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://orb.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb822_repo \
  "orb" \
  "https://pkgs.orb.net/stable/debian/orbforge.noarmor.gpg" \
  "https://pkgs.orb.net/stable/debian" \
  "orb" \
  "main"

msg_info "Installing Orb"
$STD apt install -y orb
msg_ok "Installed Orb"

msg_info "Enabling Service"
systemctl enable -q --now orb
msg_ok "Enabled Service"

motd_ssh
customize
cleanup_lxc
