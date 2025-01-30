#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://archivebox.io/

# App Default Values
APP="ArchiveBox"
var_tags="archive;bookmark"
var_cpu="2"
var_ram="1024"
var_disk="8"
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
    if [[ ! -d /opt/archivebox ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping ${APP}"
    systemctl stop archivebox
    msg_ok "Stopped ${APP}"

    msg_info "Updating ${APP}"
    cd /opt/archivebox/data
    pip install --upgrade --ignore-installed archivebox
    sudo -u archivebox archivebox init
    msg_ok "Updated ${APP}"

    msg_info "Starting ${APP}"
    systemctl start archivebox
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000/admin/login${CL}"
