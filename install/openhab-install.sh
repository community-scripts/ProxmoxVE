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
$STD apt-get install -y \
  ca-certificates \
  apt-transport-https
msg_ok "Installed Dependencies"

JAVA_VERSION="21" setup_java

msg_info "Installing openHAB"
curl -fsSL "https://openhab.jfrog.io/artifactory/api/gpg/key/public" | gpg --dearmor -o /usr/share/keyrings/openhab.gpg
chmod u=rw,g=r,o=r /usr/share/keyrings/openhab.gpg
echo "deb [signed-by=/usr/share/keyrings/openhab.gpg] https://openhab.jfrog.io/artifactory/openhab-linuxpkg stable main" >/etc/apt/sources.list.d/openhab.list
$STD apt update
$STD apt-get -y install openhab
systemctl daemon-reload
systemctl enable -q --now openhab
msg_ok "Installed openHAB"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
