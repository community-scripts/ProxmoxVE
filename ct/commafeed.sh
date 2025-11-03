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
  if check_for_gh_release "commafeed" "Athou/commafeed"; then
    msg_info "Stopping Service"
    systemctl stop commafeed
    msg_ok "Stopped Service"

    if ! [[ $(dpkg -s rsync 2>/dev/null) ]]; then
      msg_info "Installing Dependencies"
      $STD apt-get update
      $STD apt-get install -y rsync
      msg_ok "Installed Dependencies"
    fi

    if [ -d /opt/commafeed/data ] && [ "$(ls -A /opt/commafeed/data)" ]; then
      msg_info "Backing up existing data"
      mv /opt/commafeed/data /opt/data.bak
      msg_ok "Backed up existing data"
    fi

    fetch_and_deploy_gh_release "commafeed" "Athou/commafeed" "prebuild" "latest" "/opt/commafeed" "commafeed-*-h2-jvm.zip"

    if [ -d /opt/data.bak ] && [ "$(ls -A /opt/data.bak)" ]; then
      msg_info "Restoring data"
      mv /opt/data.bak /opt/commafeed/data
      msg_ok "Restored data"
    fi

    msg_info "Starting Service"
    systemctl start commafeed
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8082${CL}"
