#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/Sinofage/ProxmoxVE/refs/heads/main/misc/build.func)
# Copyright (c) community-scripts ORG
# Author: Michelle Zitzerman (Sinofage)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://beszel.dev/

# App Default Values
APP="Beszel"
var_tags="monitoring"
var_cpu="1"
var_ram="512"
var_disk="5"
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

    if [[ ! -d /opt/beszel ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -fsSL https://github.com/henrygd/beszel/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
        msg_info "Updating ${APP} to v${RELEASE}"
        /opt/beszel/beszel update
    else
        msg_ok "No update required. ${APP} is already at v${RELEASE}."
    fi

    msg_error "Beszel should be updated via the user interface."
    msg_info "Updating ${APP} LXC"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following IP:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8090${CL}"