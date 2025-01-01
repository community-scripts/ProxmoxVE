#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://triliumnext.github.io/Docs/

# App Default Values
APP="Trilium"
var_tags="notes"
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
    if [[ ! -d /opt/trilium ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/TriliumNext/Notes/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')

    msg_info "Stopping ${APP}"
    systemctl stop trilium.service
    sleep 1
    msg_ok "Stopped ${APP}"

    msg_info "Updating to ${RELEASE}"
    wget -q https://github.com/TriliumNext/Notes/releases/download/${RELEASE}/TriliumNextNotes-${RELEASE}-server-linux-x64.tar.xz
    tar -xf TriliumNextNotes-${RELEASE}-server-linux-x64.tar.xz
    cp -r trilium-linux-x64-server/* /opt/trilium/
    msg_ok "Updated to ${RELEASE}"

    msg_info "Cleaning up"
    rm -rf TriliumNextNotes-${RELEASE}-server-linux-x64.tar.xz trilium-linux-x64-server
    msg_ok "Cleaned"

    msg_info "Starting ${APP}"
    systemctl start trilium.service
    sleep 1
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"