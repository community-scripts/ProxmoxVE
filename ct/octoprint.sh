#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://octoprint.org/

APP="OctoPrint"
var_tags="${var_tags:-3d-printing}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
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
    $STD pip3 install octoprint --upgrade
    msg_ok "Updated OctoPrint"

    msg_info "Starting OctoPrint"
    systemctl start octoprint
    msg_ok "Started OctoPrint"
    msg_ok "Updated successfully!"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
