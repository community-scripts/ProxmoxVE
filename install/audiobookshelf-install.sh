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
$STD apt-get install -y gnupg
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

msg_info "Installing audiobookshelf"
curl -fsSL https://advplyr.github.io/audiobookshelf-ppa/KEY.gpg >/etc/apt/trusted.gpg.d/audiobookshelf-ppa.asc
echo "deb [signed-by=/etc/apt/trusted.gpg.d/audiobookshelf-ppa.asc] https://advplyr.github.io/audiobookshelf-ppa ./" >/etc/apt/sources.list.d/audiobookshelf.list
$STD apt-get update
$STD apt install audiobookshelf
msg_ok "Installed audiobookshelf"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
