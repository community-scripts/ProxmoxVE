#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://autobrr.com/

# App Default Values
APP="Autobrr"
var_tags="arr;"
var_cpu="2"
var_ram="2048"
var_disk="8"
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
    if [[ ! -f /root/.config/autobrr/config.toml ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping ${APP} LXC"
    systemctl stop autobrr.service
    msg_ok "Stopped ${APP} LXC"

    msg_info "Updating ${APP} LXC"
    rm -rf /usr/local/bin/*
    wget -q $(curl -s https://api.github.com/repos/autobrr/autobrr/releases/latest | grep download | grep linux_x86_64 | cut -d\" -f4)
    tar -C /usr/local/bin -xzf autobrr*.tar.gz
    rm -rf autobrr*.tar.gz
    msg_ok "Updated ${APP} LXC"

    msg_info "Starting ${APP} LXC"
    systemctl start autobrr.service
    msg_ok "Started ${APP} LXC"
    msg_ok "Updated Successfully"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7474${CL}"