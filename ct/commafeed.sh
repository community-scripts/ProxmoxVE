#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.commafeed.com/#/welcome

APP="CommaFeed"
var_tags="${var_tags:-rss-reader}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/commafeed ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/Athou/commafeed/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
  if [[ "${RELEASE}" != "$(cat ~/.commafeed 2>/dev/null)" ]] || [[ ! -f ~/.commafeed ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop commafeed
    msg_ok "Stopped ${APP}"

    if ! [[ $(dpkg -s rsync 2>/dev/null) ]]; then
      msg_info "Installing Dependencies"
      $STD apt-get update
      $STD apt-get install -y rsync
      msg_ok "Installed Dependencies"
    fi
    if [ -d /opt/commafeed/data ] && [ "$(ls -A /opt/commafeed/data)" ]; then
      mv /opt/commafeed/data /opt/data.bak
    fi
    fetch_and_deploy_gh_release "commafeed" "Athou/commafeed" "prebuild" "latest" "/opt/commafeed" "commafeed-*-h2-jvm.zip"
    
    msg_info "Updating ${APP} to ${RELEASE}"
    if [ -d /opt/commafeed/data.bak ] && [ "$(ls -A /opt/commafeed/data.bak)" ]; then
      mv /opt/commafeed/data.bak /opt/commafeed/data
    fi
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting ${APP}"
    systemctl start commafeed
    msg_ok "Started ${APP}"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8082${CL}"
