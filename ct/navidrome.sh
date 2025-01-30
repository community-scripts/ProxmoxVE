#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.navidrome.org/

# App Default Values
APP="Navidrome"
var_tags="music"
var_cpu="2"
var_ram="1024"
var_disk="4"
var_os="debian"
var_version="12"
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
    if [[ ! -d /opt/navidrome ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/navidrome/navidrome/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    msg_info "Stopping ${APP}"
    systemctl stop navidrome
    msg_ok "Stopped Navidrome"

    msg_info "Updating to v${RELEASE}"
    cd /opt
    wget -q https://github.com/navidrome/navidrome/releases/download/v${RELEASE}/navidrome_${RELEASE}_linux_amd64.tar.gz -O Navidrome.tar.gz
    tar -xvzf Navidrome.tar.gz -C /opt/navidrome/ &>/dev/null
    chmod +x /opt/navidrome/navidrome
    msg_ok "Updated ${APP}"
    rm -rf /opt/Navidrome.tar.gz

    msg_info "Starting ${APP}"
    systemctl start navidrome.service
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4533${CL}"
