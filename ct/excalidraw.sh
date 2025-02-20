#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/excalidraw/excalidraw

APP="Excalidraw"
TAGS="diagrams"
var_cpu="2"
var_ram="3072"
var_disk="6"
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

    if [[ ! -d /opt/excalidraw ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -s https://api.github.com/repos/excalidraw/excalidraw/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat /opt/excalidraw_version.txt)" ]] || [[ ! -f /opt/excalidraw_version.txt ]]; then
        msg_info "Stopping $APP"
        systemctl stop excalidraw
        msg_ok "Stopped $APP"

        msg_info "Updating $APP to v${RELEASE}"
        cd /tmp
        temp_file=$(mktemp)
        wget -q "https://github.com/excalidraw/excalidraw/archive/refs/tags/v${RELEASE}.tar.gz" -O $temp_file
        tar xzf $temp_file
        rm -rf /opt/excalidraw
        mv excalidraw-${RELEASE} /opt/excalidraw
        cd /opt/excalidraw
        yarn &> /dev/null
        msg_ok "Updated $APP to v${RELEASE}"

        msg_info "Starting $APP"
        systemctl start excalidraw
        msg_ok "Started $APP"

        msg_info "Cleaning Up"
        rm -rf $temp_file
        msg_ok "Cleanup Completed"

        echo "${RELEASE}" >/opt/excalidraw_version.txt
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
