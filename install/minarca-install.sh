#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://minarca.org/en_CA

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  apt-transport-https \
  ca-certificates \
  lsb-release
msg_ok "Installed Dependencies"

msg_info "Installing Minarca"
curl -fsSL https://www.ikus-soft.com/archive/minarca/public.key | gpg --dearmor >/usr/share/keyrings/minarca-keyring.gpg
cat <<EOF >/etc/apt/sources.list.d/minarca.sources
Types: deb
URIs: https://nexus.ikus-soft.com/repository/apt-release-$(lsb_release -sc)/
Suites: $(lsb_release -sc)
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/minarca-keyring.gpg
EOF
$STD apt update
$STD apt install -y minarca-server
msg_ok "Installed Minarca"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
