#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/HabitRPG/habitica

APP="Habitica"
var_tags="gaming"
var_cpu="2"
var_ram="4096"
var_disk="8"
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

    if [[ ! -d "/opt/habitica" ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/HabitRPG/habitica/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Stopping $APP"
        systemctl stop habitica-mongodb
        systemctl stop habitica
        systemctl stop habitica-client
        msg_ok "Stopped $APP"

        msg_info "Updating $APP to ${RELEASE}"
        temp_file=$(mktemp)
        wget -q "https://github.com/HabitRPG/habitica/archive/refs/tags/v${RELEASE}.tar.gz" -O $temp_file
        tar zxf $temp_file
        cp -rf habitica-${RELEASE}/* /opt/habitica
        cd /opt/habitica
        $STD npm i
        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Updated $APP to ${RELEASE}"

        msg_info "Starting $APP"
        systemctl start habitica-mongodb
        systemctl start habitica
        systemctl start habitica-client
        msg_ok "Started $APP"

        msg_info "Cleaning Up"
        rm -f $temp_file
        rm -rf ~/habitica-${RELEASE}
        msg_ok "Cleanup Completed"

        msg_ok "Update Successful"
    else
        msg_ok "No update required. ${APP} is already at ${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
