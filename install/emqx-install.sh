#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.emqx.com/en

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt-get install -y \
  apt-transport-https \
  ca-certificates \
  lsb-release
msg_ok "Installed dependencies"

msg_info "Installing EMQX"
curl -fsSL https://packagecloud.io/emqx/emqx/gpgkey | gpg --dearmor -o /usr/share/keyrings/emqx-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/emqx-archive-keyring.gpg] https://packagecloud.io/emqx/emqx/debian/ bookworm main" >/etc/apt/sources.list.d/emqx.list
$STD apt-get install -y emqx
msg_ok "Installed EMQX"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get autoremove
$STD apt-get autoclean
msg_ok "Cleaned"
