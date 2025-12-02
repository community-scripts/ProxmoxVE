#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://onedev.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  git-lfs
msg_ok "Installed Dependencies"

JAVA_VERSION="21" setup_java

msg_info "Installing OneDev"
RELEASE=$(curl -fsSL https://api.github.com/repos/theonedev/onedev/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
cd /opt
curl -fsSL "https://code.onedev.io/onedev/server/~site/onedev-latest.tar.gz" -o onedev-latest.tar.gz
tar -xzf onedev-latest.tar.gz
mv /opt/onedev-latest /opt/onedev
$STD /opt/onedev/bin/server.sh install
systemctl start onedev
rm -rf /opt/onedev-latest.tar.gz
echo "${RELEASE}" >~/.onedev
msg_ok "Installed OneDev"

motd_ssh
customize
cleanup_lxc
