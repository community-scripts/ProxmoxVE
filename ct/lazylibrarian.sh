#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck | Co-Author: MountyMapleSyrup (MountyMapleSyrup)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitlab.com/LazyLibrarian/LazyLibrarian

# App Default Values
APP="LazyLibrarian"
var_tags="eBook"
var_cpu="2"
var_ram="1024"
var_disk="4"
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
    if [[ ! -d /opt/LazyLibrarian/ ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping LazyLibrarian"
    systemctl stop lazylibrarian
    msg_ok "LazyLibrarian Stopped"

    msg_info "Updating $APP LXC"
    git -C /opt/LazyLibrarian pull origin master &>/dev/null
    msg_ok "Updated $APP LXC"

    msg_info "Starting LazyLibrarian"
    systemctl start lazylibrarian
    msg_ok "Started LazyLibrarian"

    msg_ok "Updated Successfully"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5299${CL}"