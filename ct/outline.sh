#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/outline/outline

APP="Outline"
var_tags="documentation"
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
    if [[ ! -d /opt/outline ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/outline/outline/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
        msg_info "Stopping Services"
        systemctl stop outline
        msg_ok "Services Stopped"

        msg_info "Updating ${APP} to ${RELEASE}"
        temp_file=$(mktemp)
        rm -rf /opt/outline/node_modules
        wget -q "https://github.com/outline/outline/archive/refs/tags/v${RELEASE}.tar.gz" -O $temp_file
        tar zxf $temp_file
        cp -rf outline-${RELEASE}/* /opt/outline
        cd /opt/outline
        export NODE_OPTIONS="--max-old-space-size=3584"
        $STD yarn install --frozen-lockfile
        $STD yarn build
        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Updated ${APP}"

        msg_info "Starting Services"
        systemctl start outline
        msg_ok "Started Services"

        msg_info "Cleaning Up"
        rm -rf $temp_file
        rm -rf $HOME/outline-${RELEASE}
        msg_ok "Cleaned"
        msg_ok "Updated Successfully"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
