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
msg_ok "Installed Dependencies"

msg_info "Installing TypeSense"


#Get installation script 
curl -O https://dl.typesense.org/releases/27.1/typesense-server-27.1-amd64.deb
#Run the Installation Script
$STD apt install ./typesense-server-27.1-amd64.deb

echo 'enable-cors = true' >> /etc/typesense/typesense-server.ini

msg_ok "Installed TypeSense"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
