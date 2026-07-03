#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rustdesk/rustdesk-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "rustdesk-hbbr" "lejianwen/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-hbbr*$(arch_resolve).deb"
fetch_and_deploy_gh_release "rustdesk-hbbs" "lejianwen/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-hbbs*$(arch_resolve).deb"
fetch_and_deploy_gh_release "rustdesk-utils" "lejianwen/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-utils*$(arch_resolve).deb"
fetch_and_deploy_gh_release "rustdesk-api" "lejianwen/rustdesk-api" "binary" "latest" "/opt/rustdesk" "rustdesk-api-server*$(arch_resolve).deb"
systemctl enable -q --now rustdesk-hbbr
systemctl enable -q --now rustdesk-hbbs
systemctl enable -q --now rustdesk-api

motd_ssh
customize
cleanup_lxc
