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
msg_ok "Installed Dependencies"

RELEASE=$(curl -s https://api.github.com/repos/juanfont/headscale/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
msg_info "Installing ${APPLICATION} v${RELEASE}"
wget -q https://github.com/juanfont/headscale/releases/download/v${RELEASE}/headscale_${RELEASE}_linux_amd64.deb
$STD dpkg -i headscale_${RELEASE}_linux_amd64.deb
systemctl enable -q --now headscale
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed ${APPLICATION} v${RELEASE}"

motd_ssh
customize

msg_info "Cleaning up"
rm headscale_${RELEASE}_linux_amd64.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
