#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bastienwirtz/homer

# App Default Values
APP="Homer"
var_tags="dashboard"
var_cpu="1"
var_ram="512"
var_disk="2"
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
    if [[ ! -d /opt/homer ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping ${APP}"
    systemctl stop homer
    msg_ok "Stopped ${APP}"

    msg_info "Backing up assets directory"
    cd ~
    mkdir -p assets-backup
    cp -R /opt/homer/assets/. assets-backup
    msg_ok "Backed up assets directory"

    msg_info "Updating ${APP}"
    rm -rf /opt/homer/*
    cd /opt/homer
    wget -q https://github.com/bastienwirtz/homer/releases/latest/download/homer.zip
    unzip homer.zip &>/dev/null
    msg_ok "Updated ${APP}"

    msg_info "Restoring assets directory"
    cd ~
    cp -Rf assets-backup/. /opt/homer/assets/
    msg_ok "Restored assets directory"

    msg_info "Cleaning"
    rm -rf assets-backup /opt/homer/homer.zip
    msg_ok "Cleaned"

    msg_info "Starting ${APP}"
    systemctl start homer
    msg_ok "Started ${APP}"
    msg_ok "Updated Successfully"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8010${CL}"