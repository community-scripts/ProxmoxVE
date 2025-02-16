#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/duplicati/duplicati/

APP="Duplicati"
var_tags="backup"
var_cpu="1"
var_ram="1024"
var_disk="10"
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
    if [[ ! -f /usr/bin/duplicati-server ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/duplicati/duplicati/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Stopping $APP"
        systemctl stop duplicati
        msg_ok "Stopped $APP"
        msg_info "Updating $APP to v${RELEASE}"
        wget -q "https://github.com/duplicati/duplicati/releases/download/v${RELEASE}/duplicati-${RELEASE}-linux-x64-gui.deb"
        $STD dpkg -i duplicati-${RELEASE}-linux-x64-gui.deb
        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Updated $APP to v${RELEASE}"

        msg_info "Starting $APP"
        systemctl start duplicati
        msg_ok "Started $APP"

        msg_info "Cleaning Up"
        rm -rf ~/duplicati-${RELEASE}-linux-x64-gui.deb
        msg_ok "Cleanup Completed"

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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8200${CL}"
