#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.hivemq.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

JAVA_VERSION="21" setup_java
fetch_and_deploy_gh_release "hivemq" "hivemq/hivemq-community-edition" "prebuild" "latest" "/opt/hivemq" "hivemq-ce-*.zip"

msg_info "Configuring HiveMQ CE"
useradd -d /opt/hivemq hivemq
chown -R hivemq:hivemq /opt/hivemq
chmod +x /opt/hivemq/bin/run.sh
cp /opt/hivemq/bin/init-script/hivemq.service /etc/systemd/system/hivemq.service
rm /opt/hivemq/conf/config.xml
mv /opt/hivemq/conf/examples/configuration/config-sample-tcp-and-websockets.xml /opt/hivemq/conf/config.xml
msg_ok "Configured HiveMQ CE"

msg_info "Starting service"
systemctl enable -q --now hivemq
msg_ok "Service started"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
