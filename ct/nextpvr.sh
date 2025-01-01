#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE
# Source: https://nextpvr.com/

# App Default Values
APP="NextPVR"
var_tags="pvr"
var_cpu="1"
var_ram="1024"
var_disk="5"
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
    if [[ ! -d /opt/nextpvr ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping ${APP}"
    systemctl stop nextpvr-server
    msg_ok "Stopped ${APP}"

    msg_info "Updating LXC packages"
    apt-get update &>/dev/null
    apt-get -y upgrade &>/dev/null
    msg_ok "Updated LXC packages"

    msg_info "Updating ${APP}"
    cd /opt
    wget -q https://nextpvr.com/nextpvr-helper.deb
    dpkg -i nextpvr-helper.deb &>/dev/null
    msg_ok "Updated ${APP}"

    msg_info "Starting ${APP}"
    systemctl start nextpvr-server
    msg_ok "Started ${APP}"

    msg_info "Cleaning Up"
    rm -rf /opt/nextpvr-helper.deb
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8866${CL}"