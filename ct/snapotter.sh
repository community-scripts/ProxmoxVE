#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://snapotter.com

APP="SnapOtter"
var_tags="${var_tags:-media;image}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_arm64="${var_arm64:-no}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/snapotter ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "snapotter" "snapotter-hq/SnapOtter"; then
    msg_info "Stopping Service"
    systemctl stop snapotter
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "snapotter" "snapotter-hq/SnapOtter" "tarball"

    msg_info "Updating SnapOtter"
    cd /opt/snapotter
    $STD npm pkg delete scripts.prepare
    $STD pnpm install --frozen-lockfile
    $STD pnpm --filter @snapotter/web build
    sed -i 's/mediapipe==0.10.21/mediapipe>=0.10.21/' /opt/snapotter/docker/feature-manifest.json
    msg_ok "Updated SnapOtter"

    msg_info "Starting Service"
    systemctl start snapotter
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:1349${CL}"
