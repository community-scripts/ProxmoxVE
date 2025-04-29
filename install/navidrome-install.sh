#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/navidrome/navidrome

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
    ffmpeg
msg_ok "Installed Dependencies"

msg_info "Installing Navidrome"
RELEASE=$(curl -fsSL https://api.github.com/repos/navidrome/navidrome/releases/latest | grep "tag_name" | awk -F '"' '{print $4}')
TMP_DEB=$(mktemp --suffix=.deb)
curl -fsSL -o "${TMP_DEB}" "https://github.com/navidrome/navidrome/releases/download/${RELEASE}/navidrome_${RELEASE#v}_linux_amd64.deb"
$STD apt-get install -y "${TMP_DEB}"
systemctl enable -q --now navidrome
echo "${RELEASE}" >/opt/Navidrome_version.txt
msg_ok "Installed Navidrome"

read -p "Do you want to install filebrowser addon? (y/n) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/filebrowser.sh)"
fi

motd_ssh
customize

msg_info "Cleaning up"
rm -f "${TMP_DEB}"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
