#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
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

msg_info "Install CUPS"
$STD apt-get install -y cups
msg_ok "Installed CUPS"

msg_info "Add lpadmin to root group"
$STD usermod -aG lpadmin root
msg_ok "Added lpadmin to root group"

msg_info "Starting Service"
systemctl enable -q --now cups
msg_ok "Started Service"

msg_info "Allow remote administration"
$STD cupsctl --remote-admin --remote-any --share-printers
msg_ok "Allowed remote administration"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
