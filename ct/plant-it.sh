#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://plant-it.org/

APP="Plant-it"
var_tags="plants;garden"
var_cpu="2"
var_ram="2048"
var_disk="5"
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

    if [[ ! -d /opt/plant-it ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -fsSL https://api.github.com/repos/MDeLuise/plant-it/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Stopping $APP"
        systemctl stop plant-it
        msg_ok "Stopped $APP"

        msg_info "Updating $APP to v${RELEASE}"
curl -fsSL "https://github.com/MDeLuise/plant-it/releases/download/${RELEASE}/server.jar" -o "/opt/plant-it/server.jar"
        cd /opt/plant-it/frontend
curl -fsSL "https://github.com/MDeLuise/plant-it/releases/download/${RELEASE}/client.tar.gz" -O $(basename "https://github.com/MDeLuise/plant-it/releases/download/${RELEASE}/client.tar.gz")
        tar -xzf client.tar.gz
        rm -f client.tar.gz
        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Updated $APP to v${RELEASE}"

        msg_info "Starting $APP"
        systemctl start plant-it
        msg_ok "Started $APP"
        msg_ok "Update Successful"
    else
        msg_ok "No update required. ${APP} is already at v${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"