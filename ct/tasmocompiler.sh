#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/benzino77/tasmocompiler

APP="TasmoCompiler"
var_tags="compiler"
var_cpu="2"
var_ram="2048"
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
    if [[ ! -d /opt/tasmocompiler ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/benzino77/tasmocompiler/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
        msg_info "Stopping $APP"
        systemctl stop tasmocompiler
        msg_ok "Stopped $APP"
        msg_info "Updating $APP to v${RELEASE}"
        cd /opt
        rm -rf /opt/tasmocompiler
        RELEASE=$(curl -s https://api.github.com/repos/benzino77/tasmocompiler/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
        wget -q https://github.com/benzino77/tasmocompiler/archive/refs/tags/v${RELEASE}.tar.gz
        tar xzf v${RELEASE}.tar.gz
        mv tasmocompiler-${RELEASE}/ /opt/tasmocompiler/
        cd /opt/tasmocompiler
        yarn install &> /dev/null
        export NODE_OPTIONS=--openssl-legacy-provider
        npm i &> /dev/null
        yarn build &> /dev/null
        msg_ok "Updated $APP to v${RELEASE}"
        msg_info "Starting $APP"
        systemctl start tasmocompiler
        msg_ok "Started $APP"
        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_info "Cleaning up"
        rm -r "/opt/v${RELEASE}.tar.gz"
        msg_ok "Cleaned"
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
