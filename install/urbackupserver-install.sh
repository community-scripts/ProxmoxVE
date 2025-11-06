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
$STD apt install -y \
  coreutils \
  debconf-utils
msg_ok "Installed Dependencies"


msg_info "Installing UrBackup Server"
curl -fsSL https://download.opensuse.org/repositories/home:uroni/Debian_12/Release.key | gpg --dearmor -o /usr/share/keyrings/home-uroni.gpg
cat <<EOF | sudo tee /etc/apt/sources.list.d/home-uroni.sources >/dev/null
Types: deb
URIs: http://download.opensuse.org/repositories/home:/uroni/Debian_12/
Suites: ./
Components: 
Signed-By: /usr/share/keyrings/home-uroni.gpg
EOF
$STD apt update
mkdir -p /opt/urbackup/backups
echo "urbackup-server urbackup/backuppath string /opt/urbackup/backups" | debconf-set-selections
$STD apt install -y urbackup-server
msg_ok "Installed UrBackup Server"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
