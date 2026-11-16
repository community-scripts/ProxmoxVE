#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.iobroker.net/#en/intro | Github: https://github.com/ioBroker/ioBroker.js-controller

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y ca-certificates
msg_ok "Installed Dependencies"

confirm_external_installer "https://iobroker.net/" "https://iobroker.net/install.sh"

NODE_VERSION="24" NPM_VERSION="11" setup_nodejs

msg_info "Installing ioBroker (Patience)"
$STD bash <(curl -fsSL https://iobroker.net/install.sh)
msg_ok "Installed ioBroker"

motd_ssh
customize
cleanup_lxc
