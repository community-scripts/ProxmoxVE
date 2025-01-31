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
$STD apt-get install -y avahi-daemon
$STD apt-get install -y gnupg2
msg_ok "Installed Dependencies"

msg_info "Setting up Homebridge Repository"
curl -sSf https://repo.homebridge.io/KEY.gpg | gpg --dearmor >/etc/apt/trusted.gpg.d/homebridge.gpg
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/homebridge.gpg] https://repo.homebridge.io stable main' >/etc/apt/sources.list.d/homebridge.list
msg_ok "Set up Homebridge Repository"

msg_info "Installing Homebridge"
$STD apt update
$STD apt-get install -y homebridge
msg_ok "Installed Homebridge"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
