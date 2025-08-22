#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MrYadro
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://recyclarr.dev/wiki/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y git
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "recyclarr" "recyclarr/recyclarr" "prebuild" "latest" "/usr/local/bin" "recyclarr-linux-x64.tar.xz"

msg_info "Configuring Recyclarr"
mkdir -p /root/.config/recyclarr
recyclarr config create
msg_ok "Configured Recyclarr"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
