#!/usr/bin/env bash
# Copyright (c) 2021-2025 community-scripts ORG
# Author: coe0718
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/openclaw/openclaw

source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

APP="OpenClaw"
var_tags="ai;assistant;automation"
var_cpu="2"
var_ram="2048"
var_disk="10"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if ! command -v openclaw &>/dev/null; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  INSTALLED=$(npm list -g openclaw --depth=0 2>/dev/null | grep openclaw | awk -F'@' '{print $2}')
  LATEST=$(npm show openclaw version 2>/dev/null)

  if [[ "${INSTALLED}" == "${LATEST}" ]]; then
    msg_ok "Already on latest version (${LATEST})"
    exit
  fi

  msg_info "Updating ${APP} from ${INSTALLED} to ${LATEST}"
  $STD npm update -g openclaw
  msg_ok "Updated ${APP} to ${LATEST}"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Before first use, run the onboarding wizard inside the container:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}openclaw onboard${CL}"
echo -e "${INFO}${YW} Once onboarded, access the Control UI at:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:18789${CL}"
