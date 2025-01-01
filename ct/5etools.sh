#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/TheRealVira/ProxmoxVE/refs/heads/5etools/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: TheRealVira
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://5e.tools/

# App Default Values
APP="5etools"
var_tags="wiki"
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
    msg_info "Updating System"

    apt-get update &>/dev/null
    apt-get -y upgrade &>/dev/null

    # Execute Update
    msg_info "Updating 5etools"
    cd /opt/5etools
    git config --global http.postBuffer 1048576000
    git config --global https.postBuffer 1048576000
    git pull --recurse-submodules --jobs=10
    cd ~
    msg_info "Updated 5etools"

    chown -R www-data: "/opt/${APP}"
    chmod -R 755 "/opt/${APP}"

    # Cleaning up
    msg_info "Cleaning Up"
    $STD apt-get -y autoremove
    $STD apt-get -y autoclean
    msg_ok "Cleanup Completed"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80${CL}"
