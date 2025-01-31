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
$STD apt-get install -y lsb-release
$STD apt-get install -y gpg
$STD apt-get install -y apt-transport-https
$STD apt-get install -y libpython3.11

msg_ok "Installed Dependencies"

msg_info "Installing Hyperion"
wget -qO- https://releases.hyperion-project.org/hyperion.pub.key | gpg --dearmor -o /usr/share/keyrings/hyperion.pub.gpg
echo "deb [signed-by=/usr/share/keyrings/hyperion.pub.gpg] https://apt.releases.hyperion-project.org/ $(lsb_release -cs) main" >/etc/apt/sources.list.d/hyperion.list
$STD apt-get update
$STD apt-get install -y hyperion
$STD systemctl enable --now hyperion@root.service
msg_ok "Installed Hyperion"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get autoremove >/dev/null
$STD apt-get autoclean >/dev/null
msg_ok "Cleaned"
