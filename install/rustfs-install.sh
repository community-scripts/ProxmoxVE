#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: halilugur
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://rustfs.com/

# Import Functions and Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_warn "WARNING: This script will run an external installer from a third-party source (https://rustfs.com/)."
msg_warn "The following code is NOT maintained or audited by our repository."
msg_warn "If you have any doubts or concerns, please review the installer code before proceeding:"
msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  https://rustfs.com/install_rustfs.sh"
echo
read -r -p "${TAB3}Do you want to continue? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  msg_error "Aborted by user. No changes have been made."
  exit 10
fi

msg_info "Installing RustFS"
echo "1" | $STD bash <(curl -fsSL https://rustfs.com/install_rustfs.sh)
msg_ok "Installed RustFS"

motd_ssh
customize
cleanup_lxc
