#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rustdesk/rustdesk-server

APP="RustDesk Server"
TAGS="remote-desktop"
var_cpu="1"
var_ram="512"
var_disk="2"
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

    if [[ ! -x /usr/bin/hbbr ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ "${RELEASE}" != "$(cat /opt/rustdesk_version.txt)" ]] || [[ ! -f /opt/rustdesk_version.txt ]]; then
        msg_info "Stopping $APP"
        systemctl stop rustdesk-hbbr
        systemctl stop rustdesk-hbbs
        msg_ok "Stopped $APP"

        msg_info "Updating $APP to v${RELEASE}"
        TEMPDIR=$(mktemp -d)
        wget -q "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-hbbr_${RELEASE}_amd64.deb" -P $TEMPDIR
        wget -q "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-hbbs_${RELEASE}_amd64.deb" -P $TEMPDIR
        wget -q "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-utils_${RELEASE}_amd64.deb" -P $TEMPDIR
        dpkg -i $TEMPDIR/*.deb &> /dev/null
        msg_ok "Updated $APP to v${RELEASE}"

        msg_info "Cleaning Up"
        rm -rf $TEMPDIR
        msg_ok "Cleanup Completed"

        echo "${RELEASE}" >/opt/rustdesk_version.txt
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
echo -e "${TAB}${GATEWAY}${BGN}${IP}${CL}"
