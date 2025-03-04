#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: thost96 (thost96)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.authelia.com/

APP="Authelia"
TAGS=""
var_cpu="1"
var_ram="512"
var_disk="2"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
base_settings

variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d "/etc/authelia/" ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
    RELEASE=$(curl -s https://api.github.com/repos/authelia/authelia/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ "${RELEASE}" != "$(/usr/bin/authelia -v | awk '{print substr($3, 2, length($2)) }' )" ]]; then
        msg_info "Updating $APP to ${RELEASE}"
        $STD apt-get update
        $STD apt-get -y upgrade
        wget -q "https://github.com/authelia/authelia/releases/download/${RELEASE}/authelia_${RELEASE}_amd64.deb"
        $STD dpkg -i "authelia_${RELEASE}_amd64.deb"
        msg_info "Cleaning Up"
        rm -f "authelia_${RELEASE}_amd64.deb"
        $STD apt-get -y autoremove
        $STD apt-get -y autoclean
        msg_ok "Cleanup Completed"
        msg_ok "Updated $APP to ${RELEASE}"
    else
        msg_ok "No update required. ${APP} is already at ${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9091${CL}"
