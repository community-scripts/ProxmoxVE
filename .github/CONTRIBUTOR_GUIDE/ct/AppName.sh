#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: [YourUserName]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: [SOURCE_URL]

# App Default Values
APP="[APP_NAME]"
# Name of the app (e.g. Google, Adventurelog, Apache-Guacamole"
TAGS="[TAGS]"
# Tags for Proxmox VE, maximum 2 pcs., no spaces allowed, separated by a semicolon ; (e.g. database | adblock;dhcp) 
var_cpu="[CPU]"
# Number of cores (1-X) (e.g. 4) - default are 2
var_ram="[RAM]"
# Amount of used RAM in MB (e.g. 2048 or 4096)
var_disk="[DISK]"
# Amount of used disk space in GB (e.g. 4 or 10)
var_os="[OS]"
# Default OS (e.g. debian, ubuntu, alpine)
var_version="[VERSION]"
# Default OS version (e.g. 12 for debian, 24.04 for ubuntu, 3.20 for alpine)
var_unprivileged="[UNPRIVILEGED]"
# 1 = unprivileged container, 0 = privileged container

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
    if [[ ! -f [INSTALLATION_CHECK_PATH] ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    # Crawling the new version and checking whether an update is required
    RELEASE=$(curl -fsSL [RELEASE_URL] | [PARSE_RELEASE_COMMAND])
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Updating $APP"

        # Stopping Services
        msg_info "Stopping $APP"
        systemctl stop [SERVICE_NAME]
        msg_ok "Stopped $APP"

        # Creating Backup
        msg_info "Creating Backup"
        tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" [IMPORTANT_PATHS]
        msg_ok "Backup Created"

        # Execute Update
        msg_info "Updating $APP to v${RELEASE}"
        [UPDATE_COMMANDS]
        msg_ok "Updated $APP to v${RELEASE}"

        # Starting Services
        msg_info "Starting $APP"
        systemctl start [SERVICE_NAME]
        sleep 2
        msg_ok "Started $APP"

        # Cleaning up
        msg_info "Cleaning Up"
        rm -rf [TEMP_FILES]
        msg_ok "Cleanup Completed"

        # Last Action
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
