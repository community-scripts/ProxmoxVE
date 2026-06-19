#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://lubelogger.com/ | Github: https://github.com/hargata/lubelog

APP="LubeLogger"
var_tags="${var_tags:-vehicle;car}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
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
  if [[ ! -f /etc/systemd/system/lubelogger.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "lubelogger" "hargata/lubelog"; then
    msg_info "Stopping Service"
    systemctl stop lubelogger
    msg_ok "Stopped Service"

    create_backup /opt/lubelogger/data/

    fetch_and_deploy_gh_release "lubelogger" "hargata/lubelog" "prebuild" "latest" "/opt/lubelogger" "LubeLogger*linux_x64.zip"
    restore_backup

    msg_info "Configuring LubeLogger"
    chmod 700 /opt/lubelogger/CarCareTracker
    cp -rf /tmp/lubeloggerData/* /opt/lubelogger/
    rm -rf /tmp/lubeloggerData
    msg_ok "Configured LubeLogger"

    msg_info "Starting Service"
    systemctl start lubelogger
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
echo -e "${GATEWAY}${BGN}http://${IP}:5000${CL}"
