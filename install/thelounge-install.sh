#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: kristocopani
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    curl \
    wget
cd /opt
curl -fsSL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh
$STD bash nodesource_setup.sh
$STD apt-get update
$STD apt-get install -y \
    nodejs
msg_ok "Installed Dependencies"

msg_info "Installing The Lounge"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/thelounge/thelounge-deb/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q https://github.com/thelounge/thelounge-deb/releases/download/v${RELEASE}/thelounge_${RELEASE}_all.deb
$STD dpkg -i ./thelounge_${RELEASE}_all.deb
msg_ok "Installed The Lounge"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "/opt/thelounge_${RELEASE}_all.deb"
rm -rf "/opt/nodesource_setup.sh"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
