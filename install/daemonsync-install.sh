#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
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
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y g++-multilib
msg_ok "Installed Dependencies"

msg_info "Installing Daemon Sync Server"
wget -qL https://github.com/community-scripts/ProxmoxVE/raw/main/misc/daemonsync_2.2.0.0059_amd64.deb
$STD dpkg -i daemonsync_2.2.0.0059_amd64.deb
msg_ok "Installed Daemon Sync Server"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf daemonsync_2.2.0.0059_amd64.deb
$STD apt-get autoremove >/dev/null
$STD apt-get autoclean >/dev/null
msg_ok "Cleaned"
