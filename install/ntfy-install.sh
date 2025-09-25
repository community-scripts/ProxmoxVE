#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ntfy.sh/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing ntfy"
mkdir -p /etc/apt/keyrings
curl -fsSL -o /etc/apt/keyrings/ntfy.gpg https://archive.ntfy.sh/apt/keyring.gpg
cat <<EOF >/etc/apt/sources.list.d/ntfy.sources 
Types: deb
URIs: https://archive.ntfy.sh/apt/
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/ntfy.gpg
EOF

$STD apt update
$STD apt install -y ntfy
systemctl enable -q --now ntfy
msg_ok "Installed ntfy"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
