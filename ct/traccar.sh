#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.traccar.org/ | Github: https://github.com/traccar/traccar

APP="Traccar"
var_tags="${var_tags:-gps;tracker}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
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

    create_backup /opt/traccar/conf/traccar.xml /opt/traccar/data /opt/traccar/media

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "traccar" "traccar/traccar" "prebuild" "latest" "/opt/traccar" "traccar-linux-64*.zip"

    msg_info "Perform Update"
    cd /opt/traccar
    $STD ./traccar.run
    msg_ok "App-Update completed"

    restore_backup
    [ -f README.txt ] || [ -f traccar.run ] && rm -f README.txt traccar.run

    msg_info "Starting Service"
    systemctl start traccar
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8082${CL}"
