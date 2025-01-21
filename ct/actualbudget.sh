#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://actualbudget.org/

# App Default Values
APP="Actual Budget"
var_tags="finance"
var_cpu="2"
var_ram="2048"
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

    if [[ ! -d /opt/actualbudget ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "Installing jq..."
        apt-get install -y jq >/dev/null 2>&1
        echo "Installed jq..."
    fi

    RELEASE=$(curl -s https://api.github.com/repos/actualbudget/actual-server/tags | jq --raw-output '.[0].name')
    if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
        msg_info "Stopping ${APP}"
        systemctl stop actualbudget
        msg_ok "${APP} Stopped"
        
        msg_info "Updating ${APP} to ${RELEASE}"
        wget -q https://github.com/actualbudget/actual-server/archive/refs/tags/${RELEASE}.tar.gz -O actual-server.tar.gz
        tar -xzvf actual-server.tar.gz >/dev/null 2>&1
        mv /opt/actualbudget /opt/actualbudget_bak
        mkdir -p /opt/actualbudget/
        mv actual-server-* /opt/actualbudget
        mv /opt/actualbudget_bak/.env /opt/actualbudget
        mv /opt/actualbudget_bak/server-files /opt/actualbudget/server-files
        cd /opt/actualbudget
        yarn install &>/dev/null
        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Updated ${APP}"
        
        msg_info "Starting ${APP}"
        systemctl start actualbudget
        msg_ok "Started ${APP}"
        
        msg_info "Cleaning Up"
        rm -rf /opt/actualbudget_bak
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5006${CL}"
