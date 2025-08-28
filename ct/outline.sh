#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/outline/outline

APP="Outline"
var_tags="${var_tags:-documentation}"
var_disk="${var_disk:-8}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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
  if [[ ! -d /opt/outline ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "outline" "outline/outline"; then
    msg_info "Stopping Services"
    systemctl stop outline
    msg_ok "Services Stopped"

    msg_info "Creating backup"
    cp /opt/outline/.env /opt
    msg_ok "Backup created"

    fetch_and_deploy_gh_release "outline" "outline/outline" "tarball"

    msg_info "Updating ${APP}"
    cd /opt/outline
    mv /opt/.env /opt/outline
    export NODE_ENV=development
    export NODE_OPTIONS="--max-old-space-size=3584"
    $STD yarn install --frozen-lockfile
    export NODE_ENV=production
    $STD yarn build
    msg_ok "Updated ${APP}"

    msg_info "Starting Services"
    systemctl start outline
    msg_ok "Started Services"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
