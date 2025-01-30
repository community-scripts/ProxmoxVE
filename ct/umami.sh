#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://umami.is/

# App Default Values
APP="Umami"
var_tags="analytics"
var_cpu="2"
var_ram="2048"
var_disk="12"
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
    if [[ ! -d /opt/umami ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    msg_info "Stopping ${APP}"
    systemctl stop umami
    msg_ok "Stopped $APP"

    msg_info "Updating ${APP}"
    cd /opt/umami
    git pull
    yarn install
    yarn build
    msg_ok "Updated ${APP}"

    msg_info "Starting ${APP}"
    systemctl start umami
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