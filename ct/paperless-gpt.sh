#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/icereed/paperless-gpt

APP="Paperless-GPT"
var_tags="${var_tags:-os}"
var_cpu="${var_cpu:-3}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-7}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/paperless-gpt ]]; then
        msg_error "No Paperless-GPT installation found!"
        exit
    fi
    RELEASE=$(curl -fsSL https://api.github.com/repos/icereed/paperless-gpt/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
        msg_info "Stopping Service"
        systemctl stop paperless-gpt
        msg_ok "Service Stopped"

        msg_info "Updating Paperless-GPT to ${RELEASE}"
        temp_file=$(mktemp)
        curl -fsSL "https://github.com/icereed/paperless-gpt/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
        tar zxf $temp_file
        rm -rf /opt/paperless-gpt
        mv paperless-gpt-${RELEASE} /opt/paperless-gpt
        cd /opt/paperless-gpt/web-app
        $STD npm install
        $STD npm run build
        cd /opt/paperless-gpt
        go mod download
        export CC=musl-gcc
        CGO_ENABLED=1 go build -tags musl -o /dev/null github.com/mattn/go-sqlite3
        CGO_ENABLED=1 go build -tags musl -o paperless-gpt .
        echo "${RELEASE}" >"/opt/paperless-gpt_version.txt"
        msg_ok "Updated Paperless-GPT to ${RELEASE}"

        msg_info "Starting Service"
        systemctl start paperless-gpt
        msg_ok "Started Service"

        msg_info "Cleaning Up"
        rm -f $temp_file
        msg_ok "Cleanup Completed"
        msg_ok "Updated successfully!"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
