#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://readeck.org/en/

# App Default Values
APP="Readeck"
var_tags="bookmark"
var_cpu="1"
var_ram="512"
var_disk="2"
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
    if [[ ! -d /opt/readeck ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating ${APP}"
    LATEST=$(curl -s https://codeberg.org/readeck/readeck/releases/ | grep -oP '(?<=Version )\d+\.\d+\.\d+' | head -1)
    systemctl stop readeck.service
    rm -rf /opt/readeck/readeck
    cd /opt/readeck
    wget -q -O readeck https://codeberg.org/readeck/readeck/releases/download/${LATEST}/readeck-${LATEST}-linux-amd64
    chmod a+x readeck
    systemctl start readeck.service
    msg_ok "Updated ${APP}"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"