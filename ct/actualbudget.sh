#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://actualbudget.org/

# App Default Values
APP="Actual Budget"
var_tags="finance"
var_cpu="2"
var_ram="2048"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

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
    if [[ ! -d /opt/actualbudget ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    if ! command -v jq >/dev/null 2>&1; then
      echo "Installing jq..."
      apt-get install -y jq >/dev/null 2>&1
      echo "Installed jq..."
    fi

    msg_info "Updating ${APP}"
    systemctl stop actualbudget
    RELEASE=$(curl -s https://api.github.com/repos/actualbudget/actual-server/tags | jq --raw-output '.[0].name')
    TEMPD="$(mktemp -d)"
    cd "${TEMPD}"
    wget -q https://codeload.github.com/actualbudget/actual-server/legacy.tar.gz/refs/tags/${RELEASE} -O - | tar -xz
    mv /opt/actualbudget /opt/actualbudget_bak
    mv actualbudget-actual-server-*/* /opt/actualbudget/
    mv /opt/actualbudget_bak/.env /opt/actualbudget
    mv /opt/actualbudget_bak/server-files /opt/actualbudget/server-files
    cd /opt/actualbudget
    yarn install &>/dev/null
    systemctl start actualbudget
    msg_ok "Successfully Updated ${APP} to ${RELEASE}"
    rm -rf "${TEMPD}"
    rm -rf /opt/actualbudget_bak
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5006${CL}"
