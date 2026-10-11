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

RELEASE=$(get_latest_github_release "wazuh/wazuh" | cut -d. -f1,2)

confirm_external_installer "https://wazuh.com/" "https://packages.wazuh.com/$RELEASE/wazuh-install.sh"

msg_info "Setup Wazuh"
curl -fsSL https://packages.wazuh.com/$RELEASE/wazuh-install.sh -o wazuh-install.sh
chmod +x wazuh-install.sh
if [ "$STD" = "silent" ]; then
  bash wazuh-install.sh -a >>~/wazuh-install.output
else
  bash wazuh-install.sh -a | tee -a ~/wazuh-install.output
fi
cat ~/wazuh-install.output | grep -E "User|Password" | awk '{$1=$1};1' | sed '1i wazuh-credentials' >~/wazuh.creds
rm -f wazuh-*.sh
rm -f ~/wazuh-install.output
msg_ok "Setup Wazuh"

# Fix LXC container false positives in rootcheck
# When running Wazuh in an LXC container, /dev/.lxc/* paths trigger false alerts
if [ -d /dev/.lxc ]; then
  msg_info "Adding LXC rootcheck exclusion"
  sed -i '/<\/rootcheck>/i \    <ignore>/dev/.lxc</ignore>' /var/ossec/etc/ossec.conf
  msg_ok "Added LXC rootcheck exclusion"
fi

motd_ssh
customize
cleanup_lxc
