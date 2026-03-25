#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Joerg Heinemann (heinemannj)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/john30/ebusd

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing ebusd"
fetch_and_deploy_gh_release "ebusd" "john30/ebusd" "binary" "latest" "" "ebusd-*_amd64-trixie_mqtt1.deb"
systemctl enable -q ebusd
msg_ok "Installed ebusd"

motd_ssh
customize
cleanup_lxc
