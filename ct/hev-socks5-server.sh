#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/miviro/ProxmoxVE/refs/heads/hev-socks5-branch/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: miviro
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/heiher/hev-socks5-server

# App Default Values
APP="hev-socks5-server"
# Name of the app (e.g. Google, Adventurelog, Apache-Guacamole"
TAGS="proxy,socks5"
# Tags for Proxmox VE, maximum 2 pcs., no spaces allowed, separated by a semicolon ; (e.g. database | adblock;dhcp)
var_cpu="2"
# Number of cores (1-X) (e.g. 4) - default are 2
var_ram="1024"
# Amount of used RAM in MB (e.g. 2048 or 4096)
var_disk="4"
# Amount of used disk space in GB (e.g. 4 or 10)
var_os="debian"
# Default OS (e.g. debian, ubuntu, alpine)
var_version="12"
# Default OS version (e.g. 12 for debian, 24.04 for ubuntu, 3.20 for alpine)
var_unprivileged="1"
# 1 = unprivileged container, 0 = privileged container

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    # Check if installation is present | -f for file, -d for folder
    if [[ ! -f /opt/hev-socks5-server ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    # Crawling the new version and checking whether an update is required
    RELEASE=$(curl -s https://api.github.com/repos/heiher/hev-socks5-server/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        # Stopping Services
        msg_info "Stopping $APP"
        systemctl stop $APP
        msg_ok "Stopped $APP"

        # Creating Backup
        msg_info "Creating Backup"
        tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" "/etc/${APP}"
        msg_ok "Backup Created"

        # Execute Update
        msg_info "Updating $APP to v${RELEASE}"
        git clone --recursive https://github.com/heiher/hev-socks5-server
        cd hev-socks5-server || exit
        make
        mv bin/${APP} /opt/${APP}
        echo "${RELEASE}" >/opt/${APP}_version.txt
        # do not overwrite existing config
        if [ ! -d "/etc/${APP}" ]; then
            mv conf/ /etc/${APP}/
        fi
        msg_ok "Updated $APP to v${RELEASE}"

        # Starting Services
        msg_info "Starting $APP"
        systemctl start $APP
        msg_ok "Started $APP"

        # Cleaning up
        msg_info "Cleaning Up"
        cd .. || exit 1
        rm -rf hev-socks5-server
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:1080${CL}"
