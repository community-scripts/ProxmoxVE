#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/kiwix/kiwix-tools

APP="Kiwix"
var_tags="${var_tags:-documentation;offline}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
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

  if ! dpkg -s kiwix-tools &>/dev/null; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  CURRENT=$(dpkg-query -W -f='${Version}' kiwix-tools 2>/dev/null)

  msg_info "Updating Package Index"
  $STD apt update
  msg_ok "Updated Package Index"

  CANDIDATE=$(apt-cache policy kiwix-tools | awk '/Candidate:/{print $2}')
  if [[ -z "$CANDIDATE" || "$CANDIDATE" == "(none)" ]]; then
    msg_error "No Candidate Version Found for kiwix-tools"
    exit
  fi

  if [[ "$CURRENT" == "$CANDIDATE" ]]; then
    echo "${CURRENT}" >/root/.kiwix
    msg_ok "Already on latest version: ${CURRENT}"
    exit
  fi

  msg_info "Stopping Service"
  systemctl stop kiwix-serve
  msg_ok "Stopped Service"

  msg_info "Updating Kiwix-Tools"
  $STD apt install -y --only-upgrade kiwix-tools
  RELEASE=$(dpkg-query -W -f='${Version}' kiwix-tools 2>/dev/null)
  echo "${RELEASE}" >/root/.kiwix
  msg_ok "Updated Kiwix-Tools"
  msg_ok "Updated successfully from ${CURRENT} to ${RELEASE}!"

  msg_info "Starting Service"
  systemctl start kiwix-serve
  msg_ok "Started Service"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
