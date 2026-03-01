#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Lucas Zampieri (zampierilucas) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Cleanuparr/Cleanuparr

APP="Cleanuparr"
var_tags="${var_tags:-arr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
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
  if [[ ! -f /opt/cleanuparr/Cleanuparr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "cleanuparr" "Cleanuparr/Cleanuparr"; then
    msg_info "Stopping Service"
    systemctl stop cleanuparr
    msg_ok "Stopped Service"

    msg_info "Backing up config"
    cp -r /opt/cleanuparr/config /opt/cleanuparr_config_backup
    msg_ok "Backed up config"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Cleanuparr" "Cleanuparr/Cleanuparr" "prebuild" "latest" "/opt/cleanuparr" "*linux-amd64.zip"

    msg_info "Restoring config"
    [[ -d /opt/cleanuparr/config ]] && rm -rf /opt/cleanuparr/config
    mv /opt/cleanuparr_config_backup /opt/cleanuparr/config
    msg_ok "Restored config"

    msg_info "Starting Service"
    systemctl start cleanuparr
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:11011${CL}"
