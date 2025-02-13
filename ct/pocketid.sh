#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Snarkenfaugister
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pocket-id/pocket-id

# App Default Values
APP="PocketID"
var_tags="identity-provider"
var_cpu="2"
var_ram="2048"
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

    if [[ ! -d /opt/pocket-id ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -fsSL https://api.github.com/repos/pocket-id/pocket-id/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Updating $APP"

        msg_info "Stopping $APP"
        systemctl stop pocketid-backend.service
        systemctl stop pocketid-frontend.service
        systemctl stop caddy.service
        msg_ok "Stopped $APP"

        msg_info "Updating $APP to v${RELEASE}"
        cd /opt
        cp -r /opt/pocket-id/backend/data /opt/data
        cp /opt/pocket-id/backend/.env /opt/backend.env
        cp /opt/pocket-id/frontend/.env /opt/frontend.env
        rm -r /opt/pocket-id
        wget -q "https://github.com/pocket-id/pocket-id/archive/refs/tags/v${RELEASE}.zip"
        unzip -q v${RELEASE}.zip
        mv pocket-id-${RELEASE} /opt/pocket-id
        mv /opt/data /opt/pocket-id/backend/data
        mv /opt/backend.env /opt/pocket-id/backend/.env 
        mv /opt/frontend.env /opt/pocket-id/frontend/.env 

        cd /opt/pocket-id/backend/cmd
        go build -o ../pocket-id-backend
        cd ../../frontend
        npm install
        npm run build
        msg_ok "Updated $APP to ${RELEASE}"

        msg_info "Starting $APP"
        systemctl start pocketid-backend.service
        systemctl start pocketid-frontend.service
        systemctl start caddy.service
        sleep 2
        msg_ok "Started $APP"

        # Cleaning up
        msg_info "Cleaning Up"
        rm -f /opt/v${RELEASE}.zip
        msg_ok "Cleanup Completed"

        echo "${RELEASE}" >/opt/${APP}_version.txt
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
echo -e "${INFO}${YW} Configure your reverse proxy to point to:${BGN} ${IP}:80${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://{PUBLIC_URL}/login/setup${CL}"
