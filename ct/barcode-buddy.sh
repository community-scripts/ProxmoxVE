#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Forceu/barcodebuddy

APP="Barcode-Buddy"
var_tags="grocery;household"
var_cpu="1"
var_ram="512"
var_disk="3"
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
  if [[ ! -d /opt/barcodebuddy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/Forceu/barcodebuddy/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop apache2
    systemctl stop barcodebuddy
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${RELEASE}"
    cd /opt
    mv /opt/barcodebuddy/ /opt/barcodebuddy-backup
    wget -q "https://github.com/Forceu/barcodebuddy/archive/refs/tags/v${RELEASE}.zip"
    unzip -q "v${RELEASE}.zip"
    mv "/opt/barcodebuddy-${RELEASE}" /opt/barcodebuddy
    cp -r /opt/barcodebuddy-backup/data/. /opt/barcodebuddy/data
    chown -R www-data:www-data /opt/barcodebuddy/data
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start apache2
    systemctl start barcodebuddy
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -r "/opt/v${RELEASE}.zip"
    rm -r /opt/barcodebuddy-backup
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
