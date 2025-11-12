#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE
# Source: https://nextpvr.com/

APP="NextPVR"
var_tags="${var_tags:-pvr}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-5}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/nextpvr ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping Service"
    systemctl stop nextpvr-server
    msg_ok "Stopped Service"

    msg_info "Updating LXC packages"
    $STD apt update
    $STD apt -y upgrade
    msg_ok "Updated LXC packages"

    msg_info "Updating ${APP}"
    cd /opt
    curl -fsSL "https://nextpvr.com/nextpvr-helper.deb" -o $(basename "https://nextpvr.com/nextpvr-helper.deb")
    $STD dpkg -i nextpvr-helper.deb
    msg_ok "Updated ${APP}"

    msg_info "Starting Service"
    systemctl start nextpvr-server
    msg_ok "Started Service"

    msg_info "Cleaning Up"
    rm -rf /opt/nextpvr-helper.deb
    msg_ok "Cleaned"
    msg_ok "Updated successfully!"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8866${CL}"
