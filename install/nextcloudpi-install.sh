#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nextcloudpi.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NCP_INSTALLER_REF="v1.58.0-rc1"

msg_warn "WARNING: This script will run an external installer from a third-party source (https://nextcloudpi.com/)."
msg_warn "The following code is NOT maintained or audited by our repository."
msg_warn "If you have any doubts or concerns, please review the installer code before proceeding:"
msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  https://raw.githubusercontent.com/nextcloud/nextcloudpi/${NCP_INSTALLER_REF}/install.sh"
echo
read -r -p "${TAB3}Do you want to continue? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  msg_error "Aborted by user. No changes have been made."
  exit 10
fi

msg_info "Installing NextCloudPi (Patience)"
BRANCH="${NCP_INSTALLER_REF}" $STD bash <(curl -fsSL "https://raw.githubusercontent.com/nextcloud/nextcloudpi/${NCP_INSTALLER_REF}/install.sh")
msg_ok "Installed NextCloudPi"

motd_ssh
customize
cleanup_lxc
