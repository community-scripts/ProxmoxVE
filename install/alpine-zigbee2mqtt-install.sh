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
$STD apk add newt
$STD apk add curl
$STD apk add openssh
$STD apk add nano
$STD apk add mc
msg_ok "Installed Dependencies"

msg_info "Installing Alpine-Zigbee2MQTT"
$STD apk add zigbee2mqtt
mkdir -p /root/.z2m
ln -s /etc/zigbee2mqtt/ /root/.z2m
chown -R root:root /etc/zigbee2mqtt /root/.z2m
sed -i -e 's/#datadir="\/var\/lib\/zigbee2mqtt"/datadir="\/etc\/zigbee2mqtt"/' -e 's/#command_user="zigbee2mqtt"/command_user="root"/' /etc/conf.d/zigbee2mqtt
$STD rc-update add zigbee2mqtt
$STD rc-service zigbee2mqtt restart
msg_ok "Installed Alpine-Zigbee2MQTT"

motd_ssh
customize
