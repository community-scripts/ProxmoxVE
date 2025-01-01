#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://petio.tv/

# App Default Values
APP="Petio"
var_tags="media"
var_cpu="2"
var_ram="1024"
var_disk="4"
var_os="ubuntu"
var_version="20.04"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/Petio ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating $APP"
    systemctl stop petio.service
    wget https://petio.tv/releases/latest -O petio-latest.zip
    unzip petio-latest.zip -d /opt/Petio
    systemctl start petio.service
    msg_ok "Updated $APP"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7777${CL}"