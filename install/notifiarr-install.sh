#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://notifiarr.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setting up Notifiarr"
$STD groupadd notifiarr
$STD useradd -g notifiarr notifiarr
setup_deb822_repo \
  "notifiarr" \
  "https://packagecloud.io/golift/pkgs/gpgkey" \
  "https://packagecloud.io/golift/pkgs/ubuntu" \
  "focal"
$STD apt install -y notifiarr
msg_ok "Setup Notifiarr"

motd_ssh
customize
cleanup_lxc
