#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: community-scripts
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ztnet.network

APP="ZTNet"
var_tags="${var_tags:-network;vpn;zerotier}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/ztnet ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping Service"
  systemctl stop ztnet
  msg_ok "Stopped Service"

  msg_info "Backing up Data"
  cp -r /opt/ztnet/data /opt/ztnet_data_backup 2>/dev/null || true
  cp /opt/ztnet/.env /opt/ztnet_env_backup 2>/dev/null || true
  msg_ok "Backed up Data"

  msg_info "Updating ZTNet"
  curl -s http://install.ztnet.network | bash
  msg_ok "Updated ZTNet"

  msg_info "Restoring Data"
  cp -r /opt/ztnet_data_backup/. /opt/ztnet/data 2>/dev/null || true
  cp /opt/ztnet_env_backup /opt/ztnet/.env 2>/dev/null || true
  rm -rf /opt/ztnet_data_backup /opt/ztnet_env_backup
  msg_ok "Restored Data"

  msg_info "Starting Service"
  systemctl start ztnet
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
