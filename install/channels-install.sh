#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://getchannels.com/dvr-server/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  chromium \
  xvfb
msg_ok "Installed Dependencies"

confirm_external_installer "https://getchannels.com" "https://getchannels.com/dvr/setup.sh"

setup_hwaccel

msg_info "Installing Channels DVR Server (Patience)"
cd /opt
$STD bash <(curl -fsSL https://getchannels.com/dvr/setup.sh)
msg_ok "Installed Channels DVR Server"

motd_ssh
customize
cleanup_lxc
