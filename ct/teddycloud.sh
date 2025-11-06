#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Dominik Siebel (dsiebel)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/toniebox-reverse-engineering/teddycloud

APP="TeddyCloud"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-2}"
var_disk="${var_disk:-8}"
var_ram="${var_ram:-1024}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "${APP}"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/teddycloud ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "teddycloud" "toniebox-reverse-engineering/teddycloud"; then
    msg_info "Stopping Service"
    systemctl stop teddycloud
    msg_ok "Stopped Service"

    msg_info "Creating backup"
    mv /opt/teddycloud /opt/teddycloud_bak
    msg_ok "Backup created"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "teddycloud" "toniebox-reverse-engineering/teddycloud" "prebuild" "latest" "/opt/teddycloud" "teddycloud.amd64.release*.zip"

    msg_info "Restoring data"
    cp -R /opt/teddycloud_bak/certs /opt/teddycloud_bak/config /opt/teddycloud_bak/data /opt/teddycloud
    msg_ok "Data restored"

    msg_info "Starting Service"
    systemctl start teddycloud
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf /opt/teddycloud_bak
    msg_ok "Cleaned up"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
