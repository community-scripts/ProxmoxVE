#!/usr/bin/env bash

# Copyright (c) 2024 tteck
# Author: itssujee
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

msg_info "Installing BlueSky PDS"
$STD sh <(curl -sSL https://raw.githubusercontent.com/bluesky-social/pds/main/installer.sh)
systemctl stop pds
sudo pdsadmin update
systemctl start pds
msg_ok "Installed BlueSky PDS"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"