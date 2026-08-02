#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: cfurrow | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gristlabs/grist-core

APP="Grist"
var_tags="${var_tags:-database;spreadsheet}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
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

  ensure_dependencies git

  if check_for_gh_release "grist" "gristlabs/grist-core"; then
    msg_info "Stopping Service"
    systemctl stop grist
    msg_ok "Stopped Service"

    create_backup /opt/grist/.env /opt/grist/docs /opt/grist/grist-sessions.db /opt/grist/landing.db

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "grist" "gristlabs/grist-core" "tarball"

    restore_backup

    msg_info "Updating Grist"
    mkdir -p /opt/grist/docs
    cd /opt/grist
    $STD yarn install
    $STD yarn run build:prod
    $STD yarn run install:python
    msg_ok "Updated Grist"

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

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8484${CL}"
