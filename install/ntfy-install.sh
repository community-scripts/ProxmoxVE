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
$STD apt-get install -y apt-transport-https
msg_ok "Installed Dependencies"

msg_info "Installing ntfy"
mkdir -p /etc/apt/keyrings
curl -fsSL https://archive.heckel.io/apt/pubkey.txt | gpg --dearmor -o /etc/apt/keyrings/archive.heckel.io.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/archive.heckel.io.gpg] https://archive.heckel.io/apt debian main" >/etc/apt/sources.list.d/archive.heckel.io.list  
$STD apt-get update
$STD apt-get install -y ntfy
systemctl enable -q --now ntfy
msg_ok "Installed ntfy"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
