#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/inventree/InvenTree

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
    sudo \
    mc \
    gnupg \
    sudo
temp_file=$(mktemp)
wget -q http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb -O $temp_file
$STD dpkg -i $temp_file
msg_ok "Installed Dependencies"

msg_info "Setting up InvenTree Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://dl.packager.io/srv/inventree/InvenTree/key | gpg --dearmor -o /etc/apt/keyrings/inventree.gpg
echo "deb [signed-by=/etc/apt/keyrings/inventree.gpg] https://dl.packager.io/srv/deb/inventree/InvenTree/stable/ubuntu 20.04 main" >/etc/apt/sources.list.d/inventree.list
msg_ok "Set up InvenTree Repository"

msg_info "Setup ${APPLICATION} (Patience)"
$STD apt-get update
$STD apt-get install -y inventree
msg_ok "Setup ${APPLICATION}"

motd_ssh
customize

msg_info "Cleaning up"
rm -f $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
