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
$STD apt-get install -y gpg
msg_ok "Installed Dependencies"

msg_info "Installing Notifiarr"
$STD groupadd notifiarr
$STD useradd -g notifiarr notifiarr
wget -qO- https://packagecloud.io/golift/pkgs/gpgkey | gpg --dearmor >/usr/share/keyrings/golift-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/golift-archive-keyring.gpg] https://packagecloud.io/golift/pkgs/ubuntu focal main" >/etc/apt/sources.list.d/golift.list
$STD apt-get update
$STD apt-get install -y notifiarr
msg_ok "Installed Notifiarr"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
