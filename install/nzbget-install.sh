#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: havardthom
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nzbget.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  par2

cat <<EOF >/etc/apt/sources.list.d/non-free.list
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
EOF
$STD apt update
$STD apt install -y unrar
rm /etc/apt/sources.list.d/non-free.list
msg_ok "Installed Dependencies"

msg_info "Installing NZBGet"
mkdir -p /usr/share/keyrings
curl -fsSL https://nzbgetcom.github.io/nzbgetcom.asc | gpg --dearmor -o /usr/share/keyrings/nzbgetcom.gpg
cat <<EOF >/etc/apt/sources.list.d/nzbgetcom.sources
Types: deb
URIs: https://nzbgetcom.github.io/deb
Suites: stable
Components: main
Architectures: all
Signed-By: /usr/share/keyrings/nzbgetcom.gpg
EOF
$STD apt update
$STD apt install -y nzbget
msg_ok "Installed NZBGet"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
