#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://meshcentral.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y ca-certificates
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing MeshCentral"
mkdir /opt/meshcentral
cd /opt/meshcentral
$STD npm install meshcentral
$STD node node_modules/meshcentral --install
msg_ok "Installed MeshCentral"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
