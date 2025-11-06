#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://homebridge.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y avahi-daemon
msg_ok "Installed Dependencies"

msg_info "Setting up Homebridge Repository"
setup_deb822_repo \
  "homebridge" \
  "https://repo.homebridge.io/KEY.gpg" \
  "https://repo.homebridge.io" \
  "stable"
msg_ok "Set up Homebridge Repository"

msg_info "Installing Homebridge"
$STD apt install -y homebridge
msg_ok "Installed Homebridge"

motd_ssh
customize
cleanup_lxc
