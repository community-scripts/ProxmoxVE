#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tanujdargan/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Auther: tanujdargan
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ThePhaseless/Byparr

APP="Byparr"
var_tags="cloudflare,solver"
var_cpu="2"
var_ram="2048"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

# If needed, explicitly set the install script path
INSTALL_SCRIPT="byparr-install"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/byparr ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating Byparr"
    cd /opt/byparr
    $STD git pull
    $STD uv sync --group test
    systemctl restart byparr.service
    msg_ok "Updated Byparr"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8191${CL}"
# Add explicit IP display for clarity
echo -e "${INFO}${YW} Container IP: ${IP}${CL}"