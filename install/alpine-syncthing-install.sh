#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://syncthing.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setup Syncthing"
$STD apk add --no-cache syncthing
rc-service syncthing start
sleep 3
rc-service syncthing stop
sed -i "{s/127.0.0.1:8384/0.0.0.0:8384/g}" /var/lib/syncthing/.local/state/syncthing/config.xml
msg_ok "Setup Syncthing"

msg_info "Enabling Syncthing Service"
$STD rc-update add syncthing default
msg_ok "Enabled Syncthing Service"

msg_info "Starting Syncthing"
$STD rc-service syncthing start
msg_ok "Started Syncthing"

motd_ssh
customize
