#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/aceberg/WatchYourLAN

# App Default Values
APP="WatchYourLAN"
var_tags="network"
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
    if [[ ! -f /lib/systemd/system/watchyourlan.service ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating $APP"
    systemctl stop watchyourlan.service
    cp -R /data/config.yaml config.yaml
    RELEASE=$(curl -s https://api.github.com/repos/aceberg/WatchYourLAN/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d '"' -f 4)
    wget -q https://github.com/aceberg/WatchYourLAN/releases/download/$RELEASE/watchyourlan_${RELEASE}_linux_amd64.deb
    dpkg -i watchyourlan_${RELEASE}_linux_amd64.deb
    cp -R config.yaml /data/config.yaml
    sed -i 's|/etc/watchyourlan/config.yaml|/data/config.yaml|' /lib/systemd/system/watchyourlan.service
    rm watchyourlan_${RELEASE}_linux_amd64.deb config.yaml
    systemctl enable -q --now watchyourlan.service
    msg_ok "Updated $APP"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8840${CL}"