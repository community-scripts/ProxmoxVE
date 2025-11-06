#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.traccar.org/

APP="Traccar"
var_tags="${var_tags:-gps;tracker}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-2}"
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
  if [[ ! -d /opt/traccar ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "traccar" "traccar/traccar"; then
    msg_info "Stopping Service"
    systemctl stop traccar
    msg_ok "Stopped Service"

    msg_info "Creating backup"
    mv /opt/traccar/conf/traccar.xml /opt
    [[ -d /opt/traccar/data ]] && mv /opt/traccar/data /opt
    [[ -d /opt/traccar/media ]] && mv /opt/traccar/media /opt
    msg_ok "Backup created"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "traccar" "traccar/traccar" "prebuild" "latest" "/opt/traccar" "traccar-linux-64*.zip"

    msg_info "Perform Update"
    cd /opt/traccar
    $STD ./traccar.run
    msg_ok "App-Update completed"

    msg_info "Restoring data"
    mv /opt/traccar.xml /opt/traccar/conf
    [[ -d /opt/data ]] && mv /opt/data /opt/traccar
    [[ -d /opt/media ]] && mv /opt/media /opt/traccar
    msg_ok "Data restored"

    msg_info "Starting Service"
    systemctl start traccar
    msg_ok "Started Service"

    msg_info "Cleaning up"
    [ -f README.txt ] || [ -f traccar.run ] && rm -f README.txt traccar.run
    $STD apt -y autoremove
    $STD apt -y autoclean
    $STD apt -y clean
    msg_ok "Cleaned up"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8082${CL}"
