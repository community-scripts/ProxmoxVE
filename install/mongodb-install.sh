#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.mongodb.com/de-de

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

read -p "${TAB3}Do you want to install MongoDB 8.0 instead of 7.0? [y/N]: " install_mongodb_8
if [[ "$install_mongodb_8" =~ ^[Yy]$ ]]; then
  MONGO_VERSION="8.0" setup_mongodb
else
  MONGO_VERSION="7.0" setup_mongodb
fi
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

motd_ssh
customize
cleanup_lxc
