#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: cfurrow | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gristlabs/grist-core

APP="Grist"
var_tags="${var_tags:-database;spreadsheet}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-6}"
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

  if [[ ! -d /opt/grist ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "grist" "gristlabs/grist-core"; then
    msg_info "Stopping Service"
    systemctl stop grist
    msg_ok "Stopped Service"

    msg_info "Creating backup"
    rm -rf /opt/grist_bak
    mv /opt/grist /opt/grist_bak
    msg_ok "Backup created"

    fetch_and_deploy_gh_release "grist" "gristlabs/grist-core" "tarball"

    msg_info "Updating ${APP}"
    mkdir -p /opt/grist/docs
    cp -n /opt/grist_bak/.env /opt/grist/.env
    cp -r /opt/grist_bak/docs/* /opt/grist/docs/
    cp /opt/grist_bak/grist-sessions.db /opt/grist/grist-sessions.db
    cp /opt/grist_bak/landing.db /opt/grist/landing.db
    cd /opt/grist
    $STD yarn install
    $STD yarn run build:prod
    $STD yarn run install:python
    msg_ok "Updated ${APP}"

    msg_info "Starting Service"
    systemctl start grist
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
echo -e "${TAB}${GATEWAY}${BGN}Grist: http://${IP}:8484${CL}"
