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

header_info "$APP"
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
    
    RELEASE=$(curl -s https://api.github.com/repos/actualbudget/actual/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ ! -f /opt/actualbudget_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/actualbudget_version.txt)" ]]; then
        msg_info "Stopping ${APP}"
        systemctl stop actualbudget
        msg_ok "${APP} Stopped"
        
        msg_info "Updating ${APP} to ${RELEASE}"
        cd /tmp
        wget -q https://github.com/actualbudget/actual-server/archive/refs/tags/v${RELEASE}.tar.gz
        mv /opt/actualbudget /opt/actualbudget_bak
        tar -xzf v${RELEASE}.tar.gz >/dev/null 2>&1
        mv *ctual-server-* /opt/actualbudget
        rm -rf /opt/actualbudget/.env
        mv /opt/actualbudget_bak/.env /opt/actualbudget
        mv /opt/actualbudget_bak/.migrate /opt/actualbudget
        mv /opt/actualbudget_bak/server-files /opt/actualbudget/server-files
        cd /opt/actualbudget
        yarn install &>/dev/null
        echo "${RELEASE}" >/opt/actualbudget_version.txt
        msg_ok "Updated ${APP}"
        
        msg_info "Starting ${APP}"
        systemctl start actualbudget
        msg_ok "Started ${APP}"
        
        msg_info "Cleaning Up"
        rm -rf /opt/actualbudget_bak
        rm -rf /tmp/v${RELEASE}.tar.gz
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
