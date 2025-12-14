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
$STD apt install -y debconf-utils
msg_ok "Installed Dependencies"

setup_deb822_repo \
  "urbackup" \
  "https://download.opensuse.org/repositories/home:uroni/Debian_13/Release.key" \
  "http://download.opensuse.org/repositories/home:/uroni/Debian_13/" \
  "./" \
  ""

msg_info "Setting up UrBackup Server"
mkdir -p /opt/urbackup/backups
echo "urbackup-server urbackup/backuppath string /opt/urbackup/backups" | debconf-set-selections
$STD apt install -y urbackup-server
msg_ok "Setup UrBackup Server"

motd_ssh
customize
cleanup_lxc
