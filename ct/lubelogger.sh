#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://lubelogger.com/

APP="LubeLogger"
var_tags="${var_tags:-vehicle;car}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
  if [[ ! -f /etc/systemd/system/lubelogger.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "lubelogger" "hargata/lubelog"; then
    msg_info "Stopping Service"
    systemctl stop lubelogger
    msg_ok "Stopped Service"

    msg_info "Backing up data"
    mkdir -p /tmp/lubeloggerData/data
    cp /opt/lubelogger/appsettings.json /tmp/lubeloggerData/appsettings.json
    cp -r /opt/lubelogger/data/ /tmp/lubeloggerData/

    # Lubelogger has moved multiples folders to the 'data' folder, and we need to move them before the update to keep the user data
    # Github Discussion: https://github.com/hargata/lubelog/discussions/787
    [[ -e /opt/lubelogger/config ]] && cp -r /opt/lubelogger/config /tmp/lubeloggerData/data/
    [[ -e /opt/lubelogger/wwwroot/translations ]] && cp -r /opt/lubelogger/wwwroot/translations /tmp/lubeloggerData/data/
    [[ -e /opt/lubelogger/wwwroot/documents ]] && cp -r /opt/lubelogger/wwwroot/documents /tmp/lubeloggerData/data/
    [[ -e /opt/lubelogger/wwwroot/images ]] && cp -r /opt/lubelogger/wwwroot/images /tmp/lubeloggerData/data/
    [[ -e /opt/lubelogger/wwwroot/temp ]] && cp -r /opt/lubelogger/wwwroot/temp /tmp/lubeloggerData/data/
    [[ -e /opt/lubelogger/log ]] && cp -r /opt/lubelogger/log /tmp/lubeloggerData/
    rm -rf /opt/lubelogger
    msg_ok "Backed up data"

    fetch_and_deploy_gh_release "lubelogger" "hargata/lubelog" "prebuild" "latest" "/opt/lubelogger" "LubeLogger*linux_x64.zip"

    msg_info "Configuring LubeLogger"
    chmod 700 /opt/lubelogger/CarCareTracker
    cp -rf /tmp/lubeloggerData/* /opt/lubelogger/
    msg_ok "Configured LubeLogger"

    msg_info "Starting Service"
    systemctl start lubelogger
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf /tmp/lubeloggerData
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
