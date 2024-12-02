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
$STD apt-get install -y curl \
  curl \
  sudo \
  mc
msg_ok "Installed Dependencies"

msg_info "Creating Service"
$STD apt-get install -y cups
$STD usermod -aG lpadmin root
systemctl enable -q --now cups
$STD cupsctl --remote-admin --remote-any --share-printers
msg_ok "Configured Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
