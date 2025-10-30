#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fuma-nama/fumadoc

APP="Fumadocs"
var_tags="${var_tags:-documentation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
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

  if [[ ! -d /opt/fumadocs ]]; then
    msg_error "No installation found in /opt/fumadocs!"
    exit
  fi

  if [[ ! -f /opt/fumadocs/.projectname ]]; then
    msg_error "Project name file not found: /opt/fumadocs/.projectname!"
    exit
  fi

  NODE_VERSION="22" NODE_MODULE="pnpm@latest" setup_nodejs
  PROJECT_NAME=$(</opt/fumadocs/.projectname)
  PROJECT_DIR="/opt/fumadocs/${PROJECT_NAME}"
  SERVICE_NAME="fumadocs_${PROJECT_NAME}.service"

  if [[ ! -d "$PROJECT_DIR" ]]; then
    msg_error "Project directory does not exist: $PROJECT_DIR"
    exit
  fi
  if ! command -v git &>/dev/null; then
    $STD apt-get install -y git
  fi

  msg_info "Stopping service $SERVICE_NAME"
  systemctl stop "$SERVICE_NAME"
  msg_ok "Stopped service $SERVICE_NAME"

  msg_info "Updating dependencies using pnpm"
  cd "$PROJECT_DIR"
  $STD pnpm up --latest
  $STD pnpm build
  msg_ok "Updated dependencies using pnpm"

  msg_info "Starting service $SERVICE_NAME"
  systemctl start "$SERVICE_NAME"
  msg_ok "Started service $SERVICE_NAME"
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
