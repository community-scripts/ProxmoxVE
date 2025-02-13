#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: nicedevil007 (NiceDevil)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE


# App Default Values
APP="Alpine-IT-Tools"
var_tags="alpine;development"
var_cpu="1"
var_ram="256"
var_disk="0.2"
var_os="alpine"
var_version="3.21"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

if [ ! -d /usr/share/nginx/html ]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
fi

RELEASE=$(curl -s https://api.github.com/repos/CorentinTh/it-tools/releases/latest | grep '"tag_name":' | cut -d '"' -f4)
if [ "${RELEASE}" != "$(cat /opt/${APP}_version.txt 2>/dev/null)" ] || [ ! -f /opt/${APP}_version.txt ]; then
    DOWNLOAD_URL="https://github.com/CorentinTh/it-tools/releases/download/${RELEASE}/it-tools-${RELEASE#v}.zip"
    msg_info "Updating ${APP} LXC"
    curl -fsSL -o it-tools.zip "$DOWNLOAD_URL"
    mkdir -p /usr/share/nginx/html
    rm -rf /usr/share/nginx/html/*
    unzip -q it-tools.zip -d /tmp/it-tools
    cp -r /tmp/it-tools/dist/* /usr/share/nginx/html
    rm -rf /tmp/it-tools
    rm -f it-tools.zip
    msg_ok "Updated Successfully"
else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
fi

exit 0
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following IP:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
