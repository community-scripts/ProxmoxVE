#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ubuntu.com/

# App Default Values
echo -e "Loading..."
APP="Ubuntu"
var_tags="os"
var_cpu="1"
var_ram="512"
var_disk="2"
var_os="ubuntu"
var_version="24.04"

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
    if [[ ! -d /var ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating ${APP} LXC"
    apt-get update &>/dev/null
    apt-get -y upgrade &>/dev/null
    msg_ok "Updated ${APP} LXC"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"