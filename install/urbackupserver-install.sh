#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Kristian Skov
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.urbackup.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  coreutils
msg_ok "Installed Dependencies"

msg_info "Installing UrBackup Server"
curl -fsSL https://download.opensuse.org/repositories/home:uroni/Debian_12/Release.key | gpg --dearmor >/etc/apt/trusted.gpg.d/home_uroni.gpg
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/home_uroni.gpg] http://download.opensuse.org/repositories/home:/uroni/Debian_12/ /' >/etc/apt/sources.list.d/home:uroni.list
$STD apt-get update -y
apt-get install -y -qq urbackup-server
msg_ok "Installed UrBackup Server"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
