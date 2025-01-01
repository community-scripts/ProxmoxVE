#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: havardthom
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
$STD apt-get install -y par2
cat <<EOF >/etc/apt/sources.list.d/non-free.list
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
EOF
$STD apt-get update
$STD apt-get install -y unrar
rm /etc/apt/sources.list.d/non-free.list
msg_ok "Installed Dependencies"

msg_info "Installing NZBGet"
mkdir -p /etc/apt/keyrings
curl -fsSL https://nzbgetcom.github.io/nzbgetcom.asc | gpg --dearmor -o /etc/apt/keyrings/nzbgetcom.gpg
echo "deb [signed-by=/etc/apt/keyrings/nzbgetcom.gpg] https://nzbgetcom.github.io/deb stable main" >/etc/apt/sources.list.d/nzbgetcom.list
$STD apt-get update
$STD apt-get install -y nzbget
msg_ok "Installed NZBGet"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
