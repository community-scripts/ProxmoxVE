#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/kohanmathers/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: KohanMathers
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitea.com/gitea/act_runner

APP="Gitea Act Runner"
var_tags="${var_tags:-ci;gitea;runner}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-0}"
var_features="${var_features:-nesting=1}"
var_description="Gitea Act Runner is the official self-hosted runner for Gitea Actions, compatible with GitHub Actions workflow syntax."

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /opt/act_runner/act_runner ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://gitea.com/api/v1/repos/gitea/act_runner/releases/latest | grep -o '"tag_name":"[^"]*"' | cut -d'"' -f4)
  VERSION="${RELEASE#v}"
  CURRENT=$(cat /opt/act_runner/version.txt 2>/dev/null || echo "none")
  if [[ "${CURRENT}" == "${RELEASE}" ]]; then
    msg_ok "Already up to date (${RELEASE})"
    exit
  fi
  msg_info "Stopping ${APP} Service"
  systemctl stop act_runner
  msg_ok "Stopped ${APP} Service"
  msg_info "Updating ${APP} to ${RELEASE}"
  ARCH=$(dpkg --print-architecture)
  curl -fsSL "https://gitea.com/gitea/act_runner/releases/download/${RELEASE}/act_runner-${VERSION}-linux-${ARCH}" \
    -o /opt/act_runner/act_runner
  chmod +x /opt/act_runner/act_runner
  echo "${RELEASE}" > /opt/act_runner/version.txt
  msg_ok "Updated ${APP}"
  msg_info "Starting ${APP} Service"
  systemctl start act_runner
  msg_ok "Started ${APP} Service"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been completed successfully!${CL}"
echo -e "${INFO}${YW} Access the runner logs with:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}journalctl -u act_runner -f${CL}"
