#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/stackblitz-labs/bolt.diy/

APP="boltdiy"
TAGS="code;ai"
var_cpu="2"
var_ram="3072"
var_disk="6"
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
    if [[ ! -d /opt/bolt.diy ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/stackblitz-labs/bolt.diy/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat /opt/boltdiy_version.txt)" ]] || [[ ! -f /opt/boltdiy_version.txt ]]; then
        msg_info "Stopping $APP"
        systemctl stop boltdiy
        msg_ok "Stopped $APP"

        msg_info "Updating $APP to v${RELEASE}"
        temp_dir=$(mktemp -d)
        temp_file=$(mktemp)
        cd $temp_dir
        wget -q "https://github.com/stackblitz-labs/bolt.diy/archive/refs/tags/v${RELEASE}.tar.gz" -O $temp_file
        tar xzf $temp_file
        cp -rf bolt.diy-${RELEASE}/* /opt/bolt.diy
        cd /opt/bolt.diy
        $STD pnpm install
        msg_ok "Updated $APP to v${RELEASE}"

        msg_info "Starting $APP"
        systemctl start boltdiy
        msg_ok "Started $APP"

        msg_info "Cleaning Up"
        rm -rf $temp_file
        rm -rf $temp_dir
        msg_ok "Cleanup Completed"

        echo "${RELEASE}" >/opt/boltdiy_version.txt
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5173${CL}"
