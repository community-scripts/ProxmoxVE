#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Joseph Stubberfield (stubbers)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/librespeed/speedtest-rust

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "librespeed-rust" "librespeed/speedtest-rust" "binary" "latest" "/opt/librespeed-rust" "librespeed-rs-x86_64-unknown-linux-gnu.deb"

msg_info "Enabling Service"
systemctl enable -q --now speedtest_rs
msg_ok "Enabled Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
