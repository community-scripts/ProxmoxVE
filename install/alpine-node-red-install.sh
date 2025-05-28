#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nodered.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apk add --no-cache \
  git \
  nodejs \
  npm
msg_ok "Installed Dependencies"

msg_info "Creating Node-RED User"
adduser -D -H -s /sbin/nologin -G users nodered
msg_ok "Created Node-RED User"

msg_info "Installing Node-RED"
$STD npm install -g --unsafe-perm node-red
msg_ok "Installed Node-RED"

msg_info "Creating /home/nodered"
mkdir -p /home/nodered
chown -R nodered:users /home/nodered
chmod 750 /home/nodered
msg_ok "Created /home/nodered"

msg_info "Creating Node-RED Service"
service_path="/etc/init.d/nodered"

echo '#!/sbin/openrc-run
description="Node-RED Service"

command="/usr/local/bin/node-red"
command_args="--max-old-space-size=128 -v"
command_user="nodered"
pidfile="/var/run/nodered.pid"
command_background="yes"

depend() {
    use net
}' >$service_path

chmod +x $service_path
msg_ok "Created Node-RED Service"

msg_info "Starting Node-RED"
$STD rc-update add nodered
$STD rc-service nodered start
msg_ok "Started Node-RED"

motd_ssh
customize
