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

msg_info "Setting up Fhem Repository"
curl -sSf https://debian.fhem.de/archive.key | gpg --dearmor >/etc/apt/trusted.gpg.d/debianfhemde-archive-keyring.gpg
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/debianfhemde-archive-keyring.gpg] https://debian.fhem.de/nightly/ /' >/etc/apt/sources.list.d/fhem.list
msg_ok "Set up Fhem Repository"

msg_info "Installing Fhem"
$STD apt-get update
$STD apt-get install -y fhem
msg_info "Installed Fhem"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
