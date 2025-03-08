#!/usr/bin/env bash

# Copyright (c) 2024 community-scripts ORG
# Author: Omar Minaya
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wazuh.com/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    sudo \
    curl
msg_ok "Installed Dependencies"

msg_info "Downloading Wazuh Installation Files"
wget https://packages.wazuh.com/4.11/wazuh-install.sh
msg_ok "Downloaded Wazuh Files"

msg_info "Installing Wazuh"
bash ./wazuh-install.sh -a
msg_ok "Installed Wazuh"

motd_ssh
customize

msg_info "Cleaning up"
rm -f wazuh-*.sh
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
