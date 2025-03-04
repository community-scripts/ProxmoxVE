#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zammad.com

APP="Zammad"
var_tags="webserver;ticket-system"
var_disk="8"
var_cpu="2"
var_ram="4096"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/zammad ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping Service"
    $STD systemctl stop zammad
    msg_info "Updating ${APP}"
    $STD apt-get update
    $STD apt-mark hold zammad
    $STD apt-get -y upgrade
    $STD apt-mark unhold zammad
    $STD apt-get -y upgrade
    msg_info "Starting Service"
    $STD systemctl start zammad
    msg_ok "Updated ${APP} LXC"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"