#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://octoprint.org/

# App Default Values
APP="OctoPrint"
var_tags="3d-printing"
var_cpu="1"
var_ram="1024"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="0"

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
    if [[ ! -d /opt/octoprint ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping OctoPrint"
    systemctl stop octoprint
    msg_ok "Stopped OctoPrint"

    msg_info "Updating OctoPrint"
    source /opt/octoprint/bin/activate
    pip3 install octoprint --upgrade &>/dev/null
    msg_ok "Updated OctoPrint"

    msg_info "Starting OctoPrint"
    systemctl start octoprint
    msg_ok "Started OctoPrint"
    msg_ok "Updated Successfully"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"