#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
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
$STD apt install -y ffmpeg
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "navidrome" "navidrome/navidrome" "binary"

msg_info "Starting Navidrome"
systemctl enable -q --now navidrome
msg_ok "Started Navidrome"

motd_ssh
customize
cleanup_lxc
