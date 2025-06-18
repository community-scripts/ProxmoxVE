#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://cronicle.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs

msg_info "Installing Cronicle Primary Server"
LATEST=$(curl -fsSL https://api.github.com/repos/jhuckaby/Cronicle/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
IP=$(hostname -I | awk '{print $1}')
mkdir -p /opt/cronicle
cd /opt/cronicle
$STD tar zxvf <(curl -fsSL https://github.com/jhuckaby/Cronicle/archive/${LATEST}.tar.gz) --strip-components 1
$STD npm install
$STD node bin/build.js dist
sed -i "s/localhost:3012/${IP}:3012/g" /opt/cronicle/conf/config.json
$STD /opt/cronicle/bin/control.sh setup
$STD /opt/cronicle/bin/control.sh start
$STD cp /opt/cronicle/bin/cronicled.init /etc/init.d/cronicled
chmod 775 /etc/init.d/cronicled
$STD update-rc.d cronicled defaults
msg_ok "Installed Cronicle Primary Server"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
