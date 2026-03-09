#!/usr/bin/env bash

# Copyright (c) 2021-2026 remz1337
# Author: remz1337
# License: MIT | https://github.com/remz1337/ProxmoxVE/raw/remz/LICENSE
# Source: https://github.com/stalwartlabs/stalwart

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Stalwart"
curl --proto '=https' --tlsv1.2 -sSf https://get.stalw.art/install.sh -o install.sh
sh install.sh /opt/stalwart
msg_ok "Installed Stalwart"

motd_ssh
customize
cleanup_lxc