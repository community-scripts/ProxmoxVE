#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://js.wiki/

APP="Wikijs"
var_tags="wiki"
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
    if [[ ! -d /opt/wikijs ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/Requarks/wiki/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Verifying whether ${APP}' new release is v3.x+ and current install uses SQLite."
        SQLITE_INSTALL=$([ -f /opt/wikijs/db.sqlite ] && echo "true" || echo "false")
        if [[ "${SQLITE_INSTALL}" == "true" && "${RELEASE}" =~ ^3.* ]]; then
            echo "SQLite is not supported in v3.x+, currently there is no update path availble."
            exit
        fi
        msg_ok "There is an update path available for ${APP} to v${RELEASE}"

        msg_info "Stopping ${APP}"
        systemctl stop wikijs
        msg_ok "Stopped ${APP}"

        msg_info "Backing up Data"
        mkdir /opt/wikijs-backup
        $SQLITE_INSTALL && cp /opt/wikijs/db.sqlite /opt/wikijs-backup
        cp -R /opt/wikijs/{config.yml,/data} /opt/wikijs-backup
        msg_ok "Backed up Data"

        msg_info "Updating ${APP}"
        rm -rf /opt/wikijs/*
        cd /opt/wikijs
        wget -q "https://github.com/requarks/wiki/releases/download/v${RELEASE}/wiki-js.tar.gz"
        tar -xzf wiki-js.tar.gz
        msg_ok "Updated ${APP}"

        msg_info "Restoring Data"
        cp -R /opt/wikijs-backup/* /opt/wikijs
        $SQLITE_INSTALL && $STD npm rebuild sqlite3
        msg_ok "Restored Data"

        msg_info "Starting ${APP}"
        systemctl start wikijs
        msg_ok "Started ${APP}"

        msg_info "Cleaning Up"
        rm -rf /opt/wikijs/wiki-js.tar.gz
        rm -rf /opt/wikijs-backup
        msg_ok "Cleanup Completed"
        msg_ok "Updated Successfully"
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