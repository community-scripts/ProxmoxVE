#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://daemonsync.me/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y g++-multilib
msg_ok "Installed Dependencies"

msg_info "Installing Daemon Sync Server"
curl -fsSL "https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/daemonsync_2.2.0.0059_amd64.deb" -o "daemonsync_2.2.0.0059_amd64.deb"
$STD dpkg -i daemonsync_2.2.0.0059_amd64.deb
rm -rf daemonsync_2.2.0.0059_amd64.deb
msg_ok "Installed Daemon Sync Server"

motd_ssh
customize
cleanup_lxc
