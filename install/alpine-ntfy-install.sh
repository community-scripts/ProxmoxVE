#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: cobalt (cobaltgit)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://ntfy.sh/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing ntfy"
$STD apk add --no-cache ntfy ntfy-openrc libcap
sed -i '/^listen-http/s/^\(.*\)$/#\1\n/' /etc/ntfy/server.yml
setcap 'cap_net_bind_service=+ep' /usr/bin/ntfy
$STD rc-update add ntfy default
$STD service ntfy start
msg_ok "Installed ntfy"

motd_ssh
customize
