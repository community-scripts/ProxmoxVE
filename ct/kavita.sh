#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.kavitareader.com/

# App Default Values
APP="Kavita"
var_tags="reader"
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
    if [[ ! -d /opt/Kavita ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating $APP LXC"
    systemctl stop kavita
    RELEASE=$(curl -s https://api.github.com/repos/Kareadita/Kavita/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    tar -xvzf <(curl -fsSL https://github.com/Kareadita/Kavita/releases/download/$RELEASE/kavita-linux-x64.tar.gz) --no-same-owner &>/dev/null
    rm -rf Kavita/config
    cp -r Kavita/* /opt/Kavita
    rm -rf Kavita
    systemctl start kavita
    msg_ok "Updated $APP LXC"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"