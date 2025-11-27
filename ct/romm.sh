#!/usr/bin/env bash

# For testing from fork/branch - set these environment variables before sourcing build.func
export INSTALL_REPO="${INSTALL_REPO:-onionrings29/ProxmoxVE}"
export INSTALL_BRANCH="${INSTALL_BRANCH:-main}"

# Source build.func from the same repo/branch for testing
source <(curl -fsSL https://raw.githubusercontent.com/${INSTALL_REPO}/${INSTALL_BRANCH}/misc/build.func)

# Copyright (c) 2021-2025 community-scripts ORG
# Author: onionrings29
# License: MIT | https://github.com/onionrings29/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rommapp/romm

APP="ROMM"
var_tags="${var_tags:-gaming;media;roms}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/romm ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping Service"
  systemctl stop romm
  msg_ok "Stopped Service"

  msg_info "Updating ${APP}"
  cd /opt/romm
  git pull origin main
  msg_ok "Updated Repository"

  msg_info "Updating Python Dependencies"
  /usr/local/bin/uv sync --all-extras
  msg_ok "Updated Python Dependencies"

  msg_info "Updating Frontend Dependencies"
  cd /opt/romm/frontend
  $STD npm install
  msg_ok "Updated Frontend Dependencies"

  msg_info "Starting Service"
  systemctl start romm
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
