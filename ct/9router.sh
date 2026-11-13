#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/decolua/9router

APP="9Router"
var_tags="${var_tags:-ai;llm;gateway}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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

  if [[ ! -d /usr/lib/node_modules/9router ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  CURRENT=$(jq -r '.version' /usr/lib/node_modules/9router/package.json)
  RELEASE=$(npm view 9router version)
  if [[ "$CURRENT" == "$RELEASE" ]]; then
    msg_ok "No update available: 9Router (${CURRENT})"
    exit
  fi

  NODE_VERSION="22" setup_nodejs

  msg_info "Stopping 9Router"
  systemctl stop 9router
  msg_ok "Stopped 9Router"

  msg_info "Updating 9Router to ${RELEASE}"
  $STD npm install -g --ignore-scripts "9router@${RELEASE}"
  msg_ok "Updated 9Router to ${RELEASE}"

  msg_info "Starting 9Router"
  systemctl start 9router
  msg_ok "Started 9Router"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:20128/dashboard${CL}"
echo -e "${INFO}${YW}Dashboard password: INITIAL_PASSWORD in /opt/9router_data/.env (inside the container)${CL}"
