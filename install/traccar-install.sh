#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.traccar.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "traccar" "traccar/traccar" "prebuild" "latest" "/opt/traccar" "traccar-linux-64*.zip"

msg_info "Configuring Traccar"
cd /opt/traccar
$STD ./traccar.run
msg_ok "Configured Traccar"

msg_info "Starting service"
systemctl enable -q --now traccar
msg_ok "Service started"

motd_ssh
customize

msg_info "Cleaning up"
[ -f README.txt ] || [ -f traccar.run ] && rm -f README.txt traccar.run
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
