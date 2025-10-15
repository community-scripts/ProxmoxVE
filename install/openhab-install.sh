#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.openhab.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  ca-certificates \
  apt-transport-https
msg_ok "Installed Dependencies"

JAVA_VERSION="21" setup_java

msg_info "Installing openHAB"
curl -fsSL "https://openhab.jfrog.io/artifactory/api/gpg/key/public" | gpg --dearmor -o /usr/share/keyrings/openhab.gpg
chmod u=rw,g=r,o=r /usr/share/keyrings/openhab.gpg
cat <<EOF >/etc/apt/sources.list.d/openhab.sources
Types: deb
URIs: https://openhab.jfrog.io/artifactory/openhab-linuxpkg
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/openhab.gpg
EOF
$STD apt update
$STD apt -y install openhab
systemctl daemon-reload
systemctl enable -q --now openhab
msg_ok "Installed openHAB"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
