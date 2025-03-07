#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) community-scripts ORG
# Author: Michelle Zitzerman (Sinofage)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://beszel.dev/

APP="Beszel"
var_tags="monitoring"
var_cpu="1"
var_ram="512"
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
    if [[ ! -d /opt/beszel ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping $APP"
    systemctl stop beszel-hub
    msg_ok "Stopped $APP"
    
    msg_info "Updating $APP"
    $STD /opt/beszel/beszel update
    msg_ok "Updated $APP"
    
    msg_info "Starting $APP"
    systemctl start beszel-hub
    msg_ok "Successfully started $APP"
    msg_ok "Update Successful"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following IP:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8090${CL}"
