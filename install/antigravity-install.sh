#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Chris Moriarty (cwmoriarty)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://antigravity.google/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  curl \
  sudo \
  git \
  jq \
  tar \
  ca-certificates
msg_ok "Installed Dependencies"

msg_info "Installing Antigravity CLI"
curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir /usr/local/bin
msg_ok "Installed Antigravity CLI"

motd_ssh
customize
cleanup_lxc
