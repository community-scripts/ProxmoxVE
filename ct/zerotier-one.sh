#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.zerotier.com/


APP="Zerotier-One"
var_tags="networking"
var_cpu="1"
var_ram="512"
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

    if [[ ! -f /usr/sbin/zerotier-one ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping Service"
    systemctl stop zerotier-one
    msg_ok "Stopping Service"
    msg_info "Updating ${APP}"
    apt-get update &>/dev/null
    apt-get -y upgrade
    msg_ok "Updated ${APP}"

    msg_info "Starting Service"
    systemctl start zerotier-one
    msg_ok "Started Service"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following IP:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:3443${CL}"
