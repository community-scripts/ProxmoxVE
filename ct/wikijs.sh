#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://js.wiki/

# App Default Values
APP="Wikijs"
var_tags="wiki"
var_cpu="1"
var_ram="512"
var_disk="3"
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
    if [[ ! -d /opt/wikijs ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping ${APP}"
    systemctl stop wikijs
    msg_ok "Stopped ${APP}"

    msg_info "Backing up Data"
    mkdir -p ~/data-backup
    cp -R /opt/wikijs/{db.sqlite,config.yml,/data} ~/data-backup
    msg_ok "Backed up Data"

    msg_info "Updating ${APP}"
    rm -rf /opt/wikijs/*
    cd /opt/wikijs
    wget -q https://github.com/Requarks/wiki/releases/latest/download/wiki-js.tar.gz
    tar xzf wiki-js.tar.gz
    msg_ok "Updated ${APP}"

    msg_info "Restoring Data"
    cp -R ~/data-backup/* /opt/wikijs
    rm -rf ~/data-backup
    npm rebuild sqlite3 &>/dev/null
    msg_ok "Restored Data"

    msg_info "Starting ${APP}"
    systemctl start wikijs
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"