#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Kometa-Team/Kometa

APP="Kometa"
TAGS="media;streaming"
var_cpu="2"
var_ram="4096"
var_disk="8"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    if [[ ! -f "/opt/kometa/kometa.py" ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/Kometa-Team/Kometa/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat /opt/kometa_version.txt)" ]] || [[ ! -f /opt/kometa_version.txt ]]; then
        msg_info "Updating $APP"
        msg_info "Stopping $APP"
        systemctl stop kometa
        msg_ok "Stopped $APP"

        msg_info "Updating $APP to ${RELEASE}"
        cd /tmp
        temp_file=$(mktemp)
        RELEASE=$(curl -s https://api.github.com/repos/Kometa-Team/Kometa/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
        wget -q "https://github.com/Kometa-Team/Kometa/archive/refs/tags/v${RELEASE}.tar.gz" -O "$temp_file"
        tar -xzf "$temp_file"
        cp /opt/kometa/config/config.yml /opt
        rm -rf /opt/kometa
        mv Kometa-${RELEASE} /opt/kometa
        cd /opt/kometa
        rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
        pip install -r requirements.txt --ignore-installed &> /dev/null
        mkdir -p config/assets
        cp /opt/config.yml config/config.yml
        echo "${RELEASE}" >/opt/kometa_version.txt
        msg_ok "Updated $APP to ${RELEASE}"

        msg_info "Starting $APP"
        systemctl start kometa
        msg_ok "Started $APP"

        msg_info "Cleaning Up"
        rm -f $temp_file
        msg_ok "Cleanup Completed"

        msg_ok "Update Successful"
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
echo -e "${INFO}${YW} Access the LXC at following IP address:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}${CL}"