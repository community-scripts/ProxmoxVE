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
msg_ok "Installed Dependencies"

RELEASE=$(curl -s https://api.github.com/repos/traccar/traccar/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
msg_info "Installing Traccar v${RELEASE}"
wget -q https://github.com/traccar/traccar/releases/download/v${RELEASE}/traccar-linux-64-${RELEASE}.zip
$STD unzip traccar-linux-64-${RELEASE}.zip
$STD ./traccar.run
systemctl enable -q --now traccar
rm -rf README.txt  traccar-linux-64-${RELEASE}.zip  traccar.run
msg_ok "Installed Traccar v${RELEASE}"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
