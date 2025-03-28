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
    newt \
    curl \
    openssh \
    nano \
    mc \
    gpg \
    git \
    nodejs \
    npm
msg_ok "Installed Dependencies"

msg_info "Creating Node-RED User"
adduser -D -H -s /sbin/nologin -G users nodered
msg_ok "Created Node-RED User"

msg_info "Installing Node-RED"
npm install -g --unsafe-perm node-red
msg_ok "Installed Node-RED"

msg_info "Creating Node-RED Service"
service_path="/etc/init.d/nodered"

echo '#!/sbin/openrc-run
description="Node-RED Service"

command="/usr/bin/node-red"
command_args="--max-old-space-size=128 -v"
command_user="nodered"
pidfile="/var/run/nodered.pid"

depend() {
    use net
}' >$service_path

chmod +x $service_path
$STD rc-update add nodered default
msg_ok "Created Node-RED Service"

msg_info "Starting Node-RED"
$STD service nodered start
msg_ok "Started Node-RED"

motd_ssh
customize
