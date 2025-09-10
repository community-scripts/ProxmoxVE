#!/usr/bin/env bash

# Copyright (c) 2024 community-scripts ORG
# Author: Omar Minaya
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wazuh.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

RELEASE=$(curl -fsSL https://api.github.com/repos/wazuh/wazuh/releases/latest | grep '"tag_name"' | awk -F '"' '{print substr($4, 2, length($2)-4)}')

msg_warn "WARNING: This script will run an external installer from a third-party source (https://wazuh.com/)."
msg_warn "The following code is NOT maintained or audited by our repository."
msg_warn "If you have any doubts or concerns, please review the installer code before proceeding:"
msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  https://packages.wazuh.com/$RELEASE/wazuh-install.sh "
echo
read -r -p "${TAB3}Do you want to continue? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  msg_error "Aborted by user. No changes have been made."
  exit 10
fi

msg_info "Setup Wazuh"
curl -fsSL https://packages.wazuh.com/$RELEASE/wazuh-install.sh -o wazuh-install.sh
chmod +x wazuh-install.sh
if [ "$STD" = "silent" ]; then
  bash wazuh-install.sh -a >>~/wazuh-install.output
else
  bash wazuh-install.sh -a | tee -a ~/wazuh-install.output
fi
cat ~/wazuh-install.output | grep -E "User|Password" | awk '{$1=$1};1' | sed '1i wazuh-credentials' >~/wazuh.creds
msg_ok "Setup Wazuh"

motd_ssh
customize

msg_info "Cleaning up"
rm -f wazuh-*.sh
rm -f ~/wazuh-install.output
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
