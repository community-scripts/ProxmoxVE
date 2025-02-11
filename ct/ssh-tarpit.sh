#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Snawoot/ssh-tarpit

# App Default Values
APP="ssh-tarpit"
TAGS="network;honeypot"
var_cpu="1"
var_ram="512"
var_disk="2"
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

    if [[ ! -f "/usr/local/bin/ssh-tarpit" ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -s https://api.github.com/repos/Snawoot/ssh-tarpit/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat /opt/ssh-tarpit_version.txt)" ]] || [[ ! -f /opt/ssh-tarpit_version.txt ]]; then
        msg_info "Updating $APP"

        msg_info "Stopping $APP"
        systemctl stop ssh-tarpit
        msg_ok "Stopped $APP"

        msg_info "Updating $APP to ${RELEASE}"
        cd /tmp
        temp_file=$(mktemp)
        wget -q "https://github.com/Snawoot/ssh-tarpit/archive/refs/tags/v${RELEASE}.tar.gz" -O "$temp_file"
        tar -xzf "$temp_file"
        rm -rf /opt/ssh-tarpit
        mv ssh-tarpit-${RELEASE} /opt/ssh-tarpit
        cd /opt/ssh-tarpit
        pip install . &> /dev/null
        echo "${RELEASE}" >/opt/ssh-tarpit_version.txt
        msg_ok "Updated $APP to ${RELEASE}"

        msg_info "Starting $APP"
        systemctl start ssh-tarpit
        msg_ok "Started $APP"

        msg_info "Cleaning Up"
        rm -f $temp_file
        $STD apt-get -y autoremove
        $STD apt-get -y autoclean
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"