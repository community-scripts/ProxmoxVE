#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz) | Co-Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://vikunja.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "vikunja" "go-vikunja/vikunja" "binary" 

msg_info "Setting up Vikunja"
sed -i 's|^# \(service:\)|\1|' /etc/vikunja/config.yml
sed -i "s|^  # \(publicurl: \).*|  \1\"http://$LOCAL_IP\"|" /etc/vikunja/config.yml
sed -i "0,/^  # \(timezone: \).*/s||  \1${tz}|" /etc/vikunja/config.yml
systemctl enable -q --now vikunja
msg_ok "Set up Vikunja"

motd_ssh
customize
cleanup_lxc
