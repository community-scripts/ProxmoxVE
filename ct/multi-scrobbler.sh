#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://foxxmd.github.io/multi-scrobbler/

APP="Multi-Scrobbler"
TAGS="music"
var_cpu="1"
var_ram="1024"
var_disk="6"
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

    # Check if installation is present | -f for file, -d for folder
    if [[ ! -d [/opt/multi-scribbler] ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    # Crawling the new version and checking whether an update is required
    RELEASE=$(curl -s https://api.github.com/repos/FoxxMD/multi-scrobbler/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Updating $APP"

        # Stopping Services
        msg_info "Stopping $APP"
        systemctl stop multi-scrobbler
        msg_ok "Stopped $APP"

        # Creating Backup
        msg_info "Creating Backup"
        tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" /opt/multi-scrobbler/config
        msg_ok "Backup Created"

        # Execute Update
        msg_info "Updating $APP to v${RELEASE}"
        wget -q https://github.com/FoxxMD/multi-scrobbler/archive/refs/tags/${RELEASE}.tar.gz
        tar -xzf ${RELEASE}.tar.gz
        cp -r multi-scrobbler-${RELEASE}/* /opt/multis-crobbler/
        rm -rf multi-scrobbler-${RELEASE}
        msg_ok "Updated $APP to v${RELEASE}"

        # Starting Services
        msg_info "Starting $APP"
        systemctl start multi-scrobbler
        sleep 2
        msg_ok "Started $APP"        


        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Update Successful"
    else
        msg_ok "No update required. ${APP} is already at v${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:[PORT]${CL}"