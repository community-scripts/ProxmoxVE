#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: finkerle
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/raydak-labs/configarr

APP="Configarr"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
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

  if [[ ! -d /opt/configarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "configarr" "raydak-labs/configarr"; then
    msg_info "Stopping Service"
    systemctl stop configarr-task.timer
    msg_ok "Stopped Service"

    mkdir -p /opt/backup/
    mv /opt/configarr/{config.yml,secrets.yml,.env} /opt/backup/
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "configarr" "raydak-labs/configarr" "prebuild" "latest" "/opt/configarr" "configarr-linux-x64.tar.xz"
    mv /opt/backup/{config.yml,secrets.yml,.env} /opt/configarr/
    rm -rf /opt/backup

    msg_info "Starting Service"
    systemctl start configarr-task.timer
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
echo -e "${INFO}${YW} Access it using the following URL (no web-ui):${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8989${CL}"
