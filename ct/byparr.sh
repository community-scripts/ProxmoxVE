#!/usr/bin/env bash
# At the beginning of both scripts
set -x  # Enables bash debugging
source <(curl -s https://raw.githubusercontent.com/tanujdargan/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Auther: tanujdargan
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ThePhaseless/Byparr

APP="Byparr"
var_tags="cloudflare,solver"
var_cpu="2"
var_ram="2048"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

# Make sure variables function runs early to set NSAPP and var_install
header_info "$APP"
variables  # This sets var_install="${NSAPP}-install"
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/byparr ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating Byparr"
    cd /opt/byparr
    $STD git pull
    $STD uv sync --group test
    systemctl restart byparr.service
    msg_ok "Updated Byparr"
    exit
}

start
build_container
description

# Explicitly get and display the IP address
IP=$(pct exec "$CTID" ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8191${CL}"
echo -e "${INFO}${YW} Container IP address: ${IP}${CL}"