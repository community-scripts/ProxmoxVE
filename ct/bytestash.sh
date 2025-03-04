#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/jordan-dalby/ByteStash

APP="ByteStash"
var_tags="code"
var_disk="4"
var_cpu="1"
var_ram="1024"
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
    if [[ ! -d /opt/bytestash ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/jordan-dalby/ByteStash/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
        msg_info "Stopping Services"
        systemctl stop bytestash-backend
        systemctl stop bytestash-frontend
        msg_ok "Services Stopped"

        msg_info "Updating ${APP} to ${RELEASE}"
        temp_file=$(mktemp)
        wget -q "https://github.com/jordan-dalby/ByteStash/archive/refs/tags/v${RELEASE}.tar.gz" -O $temp_file
        tar zxf $temp_file
        rm -rf /opt/bytestash/server/node_modules
        rm -rf /opt/bytestash/client/node_modules
        cp -rf ByteStash-${RELEASE}/* /opt/bytestash
        cd /opt/bytestash/server
        $STD npm install
        cd /opt/bytestash/client
        $STD npm install
        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Updated ${APP}"

        msg_info "Starting Services"
        systemctl start bytestash-backend
        systemctl start bytestash-frontend
        msg_ok "Started Services"

        msg_info "Cleaning Up"
        rm -f $temp_file
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
