#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: connorjfarrell
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zoneminder.readthedocs.io/en/latest/installationguide/ubuntu.html#ubuntu-22-04-jammy

APP="ZoneMinder"
var_tags="nvr"
var_cpu="2"
var_ram="2048"
var_disk="16"
var_os="ubuntu"
var_version="22.04"
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

    if [[ ! -f /usr/bin/zmpkg.pl ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -fsSL https://api.github.com/repos/ZoneMinder/zoneminder/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt 2>/dev/null || echo 'none')" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Updating to v${RELEASE}"

        systemctl stop zoneminder

        apt-get update && apt-get install --only-upgrade zoneminder -y

        systemctl start zoneminder
        sleep 2

        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Update Successful"
    else
        msg_ok "${APP} is already v${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80/zm${CL}"
