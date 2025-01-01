#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://emby.media/

# App Default Values
APP="Emby"
var_tags="media"
var_cpu="2"
var_ram="2048"
var_disk="8"
var_os="ubuntu"
var_version="22.04"
var_unprivileged="1"

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
    if [[ ! -d /opt/emby-server ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    LATEST=$(curl -sL https://api.github.com/repos/MediaBrowser/Emby.Releases/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
    msg_info "Stopping ${APP}"
    systemctl stop emby-server
    msg_ok "Stopped ${APP}"

    msg_info "Updating ${APP}"
    wget https://github.com/MediaBrowser/Emby.Releases/releases/download/${LATEST}/emby-server-deb_${LATEST}_amd64.deb &>/dev/null
    dpkg -i emby-server-deb_${LATEST}_amd64.deb &>/dev/null
    rm emby-server-deb_${LATEST}_amd64.deb
    msg_ok "Updated ${APP}"

    msg_info "Starting ${APP}"
    systemctl start emby-server
    msg_ok "Started ${APP}"
    msg_ok "Updated Successfully"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8096${CL}"
