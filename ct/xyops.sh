#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pixlcore/xyops

APP="xyOps"
var_tags="${var_tags:-scheduler;automation;monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/xyops ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "xyops" "pixlcore/xyops"; then
    msg_info "Stopping Service"
    systemctl stop xyops
    msg_ok "Stopped Service"

    create_backup /opt/xyops/data /opt/xyops/conf

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "xyops" "pixlcore/xyops" "tarball"

    restore_backup

    msg_info "Rebuilding Application"
    cd /opt/xyops
    $STD npm install
    $STD node bin/build.js dist
    chmod 644 /opt/xyops/node_modules/useragent-ng/lib/regexps.js
    msg_ok "Rebuilt Application"

    fetch_and_deploy_gh_release "xysat" "pixlcore/xysat" "tarball" "latest" "/opt/xyops/satellite"

    msg_info "Building xySat Satellite"
    cd /opt/xyops/satellite
    $STD npm install
    msg_ok "Built xySat Satellite"

    msg_info "Starting Service"
    systemctl start xyops
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
echo -e "${GATEWAY}${BGN}http://${IP}:5522${CL}"
