#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://fhem.de/

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

setup_deb822_repo \
  "debianfhemde" \
  "https://debian.fhem.de/archive.key" \
  "https://debian.fhem.de/nightly/" \
  "/" \
  ""

msg_info "Installing Fhem"
$STD apt install -y fhem
msg_ok "Installed Fhem"

motd_ssh
customize
cleanup_lxc
