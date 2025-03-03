#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tomcat.apache.org/

APP="Apache-Tomcat"
var_tags="webserver"
var_disk="5"
var_cpu="1"
var_ram="1024"
var_os="debian"
var_version="12"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if ! ls -d /opt/tomcat-* >/dev/null 2>&1; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_error "Currently we dont provide an Update of Apache Tomcat."
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
