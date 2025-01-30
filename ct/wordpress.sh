#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 communtiy-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wordpress.org/

## App Default Values
APP="Wordpress"
var_tags="blog;cms"
var_disk="5"
var_cpu="2"
var_ram="2048"
var_os="debian"
var_version="12"

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
    if [[ ! -d /var/www/html/wordpress ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_error "Wordpress should be updated via the user interface."
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN} ${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/${CL}"