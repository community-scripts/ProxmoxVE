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

msg_warn "WARNING: This script will run an external installer from a third-party source (https://getchannels.com)."
msg_warn "The following code is NOT maintained or audited by our repository."
msg_warn "If you have any doubts or concerns, please review the installer code before proceeding:"
msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  https://getchannels.com/dvr/setup.sh"
echo
read -r -p "${TAB3}Do you want to continue? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  msg_error "Aborted by user. No changes have been made."
  exit 10
fi

setup_hwaccel

msg_info "Installing Channels DVR Server (Patience)"
cd /opt
$STD bash <(curl -fsSL https://getchannels.com/dvr/setup.sh)
sed -i -e 's/^sgx:x:104:$/render:x:104:root/' -e 's/^render:x:106:root$/sgx:x:106:/' /etc/group
msg_ok "Installed Channels DVR Server"

motd_ssh
customize
cleanup_lxc
