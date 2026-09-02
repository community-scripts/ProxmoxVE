#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/diegosouzapw/OmniRoute

APP="OmniRoute"
var_tags="${var_tags:-ai;gateway;llm}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/omniroute ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Checking for Updates"
  local LATEST
  LATEST=$(npm view omniroute version 2>/dev/null)
  if [[ -z "$LATEST" ]]; then
    msg_error "Could not determine latest OmniRoute version"
    exit
  fi
  if [[ "$LATEST" == "$(omniroute --version 2>/dev/null)" ]]; then
    msg_ok "Already up to date (${LATEST})"
    exit
  fi
  msg_ok "New version available: ${LATEST}"

  NODE_VERSION="26" setup_nodejs
  
  msg_info "Stopping Service"
  systemctl stop omniroute
  msg_ok "Stopped Service"

  msg_info "Updating OmniRoute to ${LATEST}"
  $STD npm install -g omniroute@latest
  msg_ok "Updated OmniRoute to ${LATEST}"

  msg_info "Starting Service"
  systemctl start omniroute
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:20128${CL}"
echo -e "${INFO}${YW} The admin password is stored in /opt/omniroute/.env (INITIAL_PASSWORD)${CL}"
