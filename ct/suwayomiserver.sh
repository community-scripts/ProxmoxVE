#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Suwayomi/Suwayomi-Server

APP="SuwayomiServer"
var_tags="media;manga"
var_cpu="1"
var_ram="1024"
var_disk="4"
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

    if [[ ! -f /usr/bin/suwayomi-server ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/Suwayomi/Suwayomi-Server/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ "${RELEASE}" != "$(cat /opt/suwayomi-server_version.txt)" ]] || [[ ! -f /opt/suwayomi-server_version.txt ]]; then
        msg_info "Updating $APP"
        msg_info "Stopping $APP"
        systemctl stop suwayomi-server
        msg_ok "Stopped $APP"
        msg_info "Updating $APP to v${RELEASE}"
        cd /tmp
        URL=$(curl -s https://api.github.com/repos/Suwayomi/Suwayomi-Server/releases/latest | grep "browser_download_url" | awk '{print substr($2, 2, length($2)-2) }' |  tail -n+2 | head -n 1)
        wget -q $URL
        $STD dpkg -i /tmp/*.deb
        msg_ok "Updated $APP to v${RELEASE}"
        msg_info "Starting $APP"
        systemctl start suwayomi-server
        msg_ok "Started $APP"
        msg_info "Cleaning Up"
        rm -f *.deb
        msg_ok "Cleanup Completed"
        echo "${RELEASE}" >/opt/suwayomi-server_version.txt.txt
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4567${CL}"
