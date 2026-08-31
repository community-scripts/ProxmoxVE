#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ulsklyc/yuvomi

APP="Yuvomi"
var_tags="${var_tags:-family;planner;calendar}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -d /opt/yuvomi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "yuvomi" "ulsklyc/yuvomi"; then
    msg_info "Stopping Service"
    systemctl stop yuvomi
    msg_ok "Stopped Service"

    create_backup /opt/yuvomi/data /opt/yuvomi/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "yuvomi" "ulsklyc/yuvomi" "tarball"
    NODE_VERSION="24" setup_nodejs

    msg_info "Installing Node.js Dependencies"
    cd /opt/yuvomi
    $STD npm ci --omit=dev
    msg_ok "Installed Node.js Dependencies"

    restore_backup

    msg_info "Starting Service"
    systemctl start yuvomi
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
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
