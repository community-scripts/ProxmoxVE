#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: liecno
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/FunkeyFlo/ps5-mqtt/

# App Default Values
APP="PS5-MQTT"
var_tags="smarthome;automation"
var_cpu="1"
var_ram="512"
var_disk="3"
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

    if [[ ! -d /opt/ps5-mqtt ]]; then
        msg_error "No ${APP} installation found!"
        exit
    fi

    RELEASE=$(curl -s https://api.github.com/repos/FunkeyFlo/ps5-mqtt/releases/latest | jq -r '.tag_name')

    if [[ "${RELEASE}" != "$(cat /opt/ps5-mqtt_version.txt)" ]]; then
        msg_info "Stopping service"
        systemctl stop ps5-mqtt
        msg_ok "Stopped service"

        msg_info "Updating PS5-MQTT to ${RELEASE}"
        wget -P /tmp -q https://github.com/FunkeyFlo/ps5-mqtt/archive/refs/tags/${RELEASE}.tar.gz
        rm -rf /opt/ps5-mqtt
        tar zxf /tmp/${RELEASE}.tar.gz -C /opt
        mv /opt/ps5-mqtt-* /opt/ps5-mqtt
        rm /tmp/${RELEASE}.tar.gz
        echo ${RELEASE} > /opt/ps5-mqtt_version.txt
        msg_ok "Updated PS5-MQTT"

        msg_info "Building new PS5-MQTT version"
        cd /opt/ps5-mqtt/ps5-mqtt/
        npm install &>/dev/null
        npm run build &>/dev/null
        msg_ok "Built new PS5-MQTT version"

        msg_info "Starting service"
        systemctl start ps5-mqtt
        msg_ok "Started service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8645${CL}"
