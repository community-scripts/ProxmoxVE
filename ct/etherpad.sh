#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: John McLear (JohnMcLear)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://etherpad.org

APP="Etherpad"
var_tags="${var_tags:-docs;collaboration;editor}"
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

  if [[ ! -d /opt/etherpad-lite ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "etherpad-lite" "ether/etherpad"; then
    msg_info "Stopping Service"
    systemctl stop etherpad
    msg_ok "Stopped Service"

    create_backup /opt/etherpad-lite/.env /opt/etherpad-lite/APIKEY.txt /opt/etherpad-lite/settings.json
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "etherpad-lite" "ether/etherpad" "tarball"
    restore_backup

    msg_info "Rebuilding Etherpad"
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    $STD corepack enable
    cd /opt/etherpad-lite
    $STD pnpm install --frozen-lockfile
    $STD pnpm run build:etherpad
    msg_ok "Rebuilt Etherpad"

    msg_info "Starting Service"
    systemctl start etherpad
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9001${CL}"
