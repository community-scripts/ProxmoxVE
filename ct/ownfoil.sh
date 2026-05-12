#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: pajjski
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/a1ex4/ownfoil

APP="ownfoil"
var_tags="${var_tags:-gaming}"
var_cpu="${var_cpu:-1}"
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

  if [[ ! -d /opt/ownfoil ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "ownfoil" "a1ex4/ownfoil"; then
    msg_info "Stopping Service"
    systemctl stop ownfoil
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/ownfoil/app/config /opt/ownfoil_data_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "ownfoil" "a1ex4/ownfoil" "tarball"

    msg_info "Installing Dependencies"
    cd /opt/ownfoil
    $STD source .venv/bin/activate
    $STD uv pip install -r requirements.txt
    msg_ok "Installed Dependencies"

    msg_info "Restoring Data"
    cp -r /opt/ownfoil_data_backup /opt/ownfoil/app/config
    rm -rf /opt/ownfoil_data_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start ownfoil
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8465${CL}"
