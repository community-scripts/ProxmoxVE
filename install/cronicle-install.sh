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
fetch_and_deploy_gh_release "cronicle" "jhuckaby/Cronicle"

msg_info "Configuring Cronicle Primary Server"
IP=$(hostname -I | awk '{print $1}')
cd /opt/cronicle
$STD npm install
$STD node bin/build.js dist
sed -i "s/localhost:3012/${IP}:3012/g" /opt/cronicle/conf/config.json
$STD /opt/cronicle/bin/control.sh setup
$STD /opt/cronicle/bin/control.sh start
msg_ok "Configured Cronicle Primary Server"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
