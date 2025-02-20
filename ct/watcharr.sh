#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sbondCo/Watcharr

APP="Watcharr"
var_tags="media"
var_cpu="1"
var_ram="1024"
var_disk="4"
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
    if [[ ! -d /opt/watcharr ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/sbondCo/Watcharr/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Updating $APP"

        msg_info "Stopping $APP"
        systemctl stop watcharr
        msg_ok "Stopped $APP"

        msg_info "Updating $APP to v${RELEASE}"
        temp_file=$(mktemp)
        temp_folder=$(mktemp -d)
        wget -q "https://github.com/sbondCo/Watcharr/archive/refs/tags/v${RELEASE}.tar.gz" -O "$temp_file"
        tar -xzf "$temp_file" -C "$temp_folder"
        rm -f /opt/watcharr/server/watcharr
        rm -rf /opt/watcharr/server/ui
        cp -rf ${temp_folder}/Watcharr-${RELEASE}/* /opt/watcharr
        cd /opt/watcharr
        export GOOS=linux
        npm i &> /dev/null
        npm run build &> /dev/null
        mv ./build ./server/ui
        cd server
        go mod download
        go build -o ./watcharr
        msg_ok "Updated $APP to v${RELEASE}"

        msg_info "Starting $APP"
        systemctl start watcharr
        msg_ok "Started $APP"

        msg_info "Cleaning Up"
        rm -f ${temp_file}
        rm -rf ${temp_folder}
        msg_ok "Cleanup Completed"

        echo "${RELEASE}" >/opt/${APP}_version.txt
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3080${CL}"
