#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://notifiarr.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Notifiarr"
$STD groupadd notifiarr
$STD useradd -g notifiarr notifiarr
curl -fsSL "https://packagecloud.io/golift/pkgs/gpgkey" | gpg --dearmor >/usr/share/keyrings/golift-archive-keyring.gpg
cat <<EOF >/etc/apt/sources.list.d/golift.sources
Types: deb
URIs: https://packagecloud.io/golift/pkgs/ubuntu
Suites: focal
Components: main
Signed-By: /usr/share/keyrings/golift-archive-keyring.gpg
EOF
$STD apt update
$STD apt install -y notifiarr
msg_ok "Installed Notifiarr"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
