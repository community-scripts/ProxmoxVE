#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rogerfar/rdt-client

# App Default Values
APP="RDTClient"
var_tags="torrent"
var_cpu="1"
var_ram="1024"
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
    if [[ ! -d /opt/rdtc/ ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping ${APP}"
    systemctl stop rdtc
    msg_ok "Stopped ${APP}"

    msg_info "Updating ${APP}"
    if dpkg-query -W dotnet-sdk-8.0 >/dev/null 2>&1; then
        apt-get remove --purge -y dotnet-sdk-8.0 &>/dev/null
        apt-get install -y dotnet-sdk-9.0 &>/dev/null
    fi
    mkdir -p rdtc-backup
    cp -R /opt/rdtc/appsettings.json rdtc-backup/
    wget -q https://github.com/rogerfar/rdt-client/releases/latest/download/RealDebridClient.zip
    unzip -oqq RealDebridClient.zip -d /opt/rdtc
    cp -R rdtc-backup/appsettings.json /opt/rdtc/
    msg_ok "Updated ${APP}"

    msg_info "Starting ${APP}"
    systemctl start rdtc
    msg_ok "Started ${APP}"

    msg_info "Cleaning Up"
    rm -rf rdtc-backup RealDebridClient.zip
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6500${CL}"