#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

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
  mc \
  sudo \
  default-jdk \
  git \
  git-lfs
msg_ok "Installed Dependencies"

msg_info "Installing Redash"
cd /tmp
git clone https://github.com/getredash/setup/
cd setup
chmox +x ./setup.sh
$STD ./setup.sh
msg_ok "Installed Redash"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
