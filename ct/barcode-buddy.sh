#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Forceu/barcodebuddy

APP="Barcode-Buddy"
var_tags="${var_tags:-grocery;household}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-3}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

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

  if check_for_gh_release "barcodebuddy" "Forceu/barcodebuddy"; then
    msg_info "Stopping Service"
    systemctl stop apache2
    systemctl stop barcodebuddy
    msg_ok "Stopped Service"

    msg_info "Backing up data"
    mv /opt/barcodebuddy/ /opt/barcodebuddy-backup
    msg_ok "Backed up data"

    fetch_and_deploy_gh_release "barcodebuddy" "Forceu/barcodebuddy"

    msg_info "Configuring ${APP}"
    cp -r /opt/barcodebuddy-backup/data/. /opt/barcodebuddy/data
    chown -R www-data:www-data /opt/barcodebuddy/data
    msg_ok "Configured ${APP}"

    msg_info "Starting Service"
    systemctl start apache2
    systemctl start barcodebuddy
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -r /opt/barcodebuddy-backup
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
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
