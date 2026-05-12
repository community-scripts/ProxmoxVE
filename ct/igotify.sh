#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: pfassina
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/androidseb25/iGotify-Notification-Assistent

APP="iGotify"
var_tags="${var_tags:-notifications;gotify}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
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

  if [[ ! -d /opt/igotify ]]; then
    msg_error "No iGotify Installation Found!"
    exit
  fi

  if check_for_gh_release "igotify" "androidseb25/iGotify-Notification-Assistent"; then
    msg_info "Stopping Service"
    systemctl stop igotify
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration"
    cp /opt/igotify/.env /opt/igotify.env.bak
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "igotify" "androidseb25/iGotify-Notification-Assistent" "prebuild" "latest" "/opt/igotify" "iGotify-Notification-Service-amd64-v*.zip"

    msg_info "Restoring Configuration"
    cp /opt/igotify.env.bak /opt/igotify/.env
    rm -f /opt/igotify.env.bak
    msg_ok "Restored Configuration"

    msg_info "Starting Service"
    systemctl start igotify
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
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
