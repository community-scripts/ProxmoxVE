#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/TheRealVira/ProxmoxVE/refs/heads/5etools/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: TheRealVira
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://5e.tools/

# App Default Values
APP="5etools"
TAGS="wiki"
var_cpu="1"
var_ram="512"
var_disk="10"
var_os="debian"
var_version="12"
var_unprivileged="1"
var_offline_mode="TRUE"

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

    # Check if installation is present | -f for file, -d for folder
    if [[ ! -d "/opt/${APP}" ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    # Crawling the new version and checking whether an update is required
    RELEASE=$(curl -s https://api.github.com/repos/5etools-mirror-3/5etools-src/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f "/opt/5etools_version.txt" ]]; then
        msg_info "Updating $APP to ${RELEASE}"

        apt-get update &>/dev/null
        apt-get -y upgrade &>/dev/null

        # Creating Backup
        msg_info "Creating Backup"
        mv "/opt/${APP}" "/opt/${APP}-backup"
        msg_ok "Backup Created"

        # Execute Update
        wget -q "https://github.com/5etools-mirror-3/5etools-src/archive/refs/tags/${RELEASE}.zip"
        unzip -q "${RELEASE}.zip" -d "/opt/${APP}"
        rm -rf "${RELEASE}.zip"
        wget -q "https://github.com/5etools-mirror-2/5etools-img/archive/refs/tags/${RELEASE}.zip"
        unzip -q "${RELEASE}.zip" -d "/opt/${APP}/img"
        rm -rf "${RELEASE}.zip"

        chown -R www-data: "/opt/${APP}"
        chmod -R 755 "/opt/${APP}"

        # Cleaning up
        msg_info "Cleaning Up"
        $STD apt-get -y autoremove
        $STD apt-get -y autoclean
        msg_ok "Cleanup Completed"

        # Last Action
        echo "${RELEASE}" >/opt/${APP}_version.txt
        msg_ok "Updated $APP to ${RELEASE}"

        # Starting httpd
        msg_info "Starting apache"
        apache2ctl start
        msg_ok "Started apache"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80${CL}"