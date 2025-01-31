#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y gpg
msg_ok "Installed Dependencies"

msg_info "Installing OpenJDK"
wget -qO- https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor >/etc/apt/trusted.gpg.d/adoptium.gpg
echo 'deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main' >/etc/apt/sources.list.d/adoptium.list
$STD apt-get update
$STD apt-get install -y temurin-17-jre
msg_ok "Installed OpenJDK"

msg_info "Installing HiveMQ CE"
RELEASE=$(curl -s https://api.github.com/repos/hivemq/hivemq-community-edition/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q https://github.com/hivemq/hivemq-community-edition/releases/download/${RELEASE}/hivemq-ce-${RELEASE}.zip
unzip -q hivemq-ce-${RELEASE}.zip
mkdir -p /opt/hivemq
mv hivemq-ce-${RELEASE}/* /opt/hivemq
useradd -d /opt/hivemq hivemq
chown -R hivemq:hivemq /opt/hivemq
chmod +x /opt/hivemq/bin/run.sh
cp /opt/hivemq/bin/init-script/hivemq.service /etc/systemd/system/hivemq.service
rm /opt/hivemq/conf/config.xml
mv /opt/hivemq/conf/examples/configuration/config-sample-tcp-and-websockets.xml /opt/hivemq/conf/config.xml
systemctl enable -q --now hivemq
msg_ok "Installed HiveMQ CE"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf hivemq-ce-${RELEASE}.zip
rm -rf ../hivemq-ce-${RELEASE}
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
