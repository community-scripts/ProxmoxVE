#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Sync-in/server

APP="Sync-in"
var_tags="${var_tags:-files;sync;collaboration}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/sync-in/node_modules/@sync-in ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "sync-in" "Sync-in/server"; then
    msg_info "Stopping Service"
    systemctl stop sync-in
    msg_ok "Stopped Service"

    msg_info "Updating Sync-in"
    $STD npm install --prefix /opt/sync-in "@sync-in/server@${CHECK_UPDATE_RELEASE#v}"
    msg_ok "Updated Sync-in"

    msg_info "Running Database Migrations"
    cd /opt/sync-in
    $STD npx sync-in-server migrate-db
    msg_ok "Ran Database Migrations"

    VERSION=$(node -pe "require('/opt/sync-in/node_modules/@sync-in/server/package.json').version" 2>/dev/null || echo "")
    [[ -n "$VERSION" ]] && echo "$VERSION" >~/.sync-in

    msg_info "Starting Service"
    systemctl start sync-in
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
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
