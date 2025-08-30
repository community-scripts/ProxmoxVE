#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TriliumNext/Trilium

APP="Trilium"
var_tags="${var_tags:-notes}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
  if [[ ! -d /opt/trilium ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "Trilium" "TriliumNext/Trilium"; then
    if [[ -d /opt/trilium/db ]]; then
      DB_PATH="/opt/trilium/db"
      DB_RESTORE_PATH="/opt/trilium/db"
    elif [[ -d /opt/trilium/assets/db ]]; then
      DB_PATH="/opt/trilium/assets/db"
      DB_RESTORE_PATH="/opt/trilium/assets/db"
    else
      msg_error "Database not found in either /opt/trilium/db or /opt/trilium/assets/db"
      exit 1
    fi

    msg_info "Stopping ${APP}"
    systemctl stop trilium
    sleep 1
    msg_ok "Stopped ${APP}"

    msg_info "Backing up Database"
    mkdir -p /opt/trilium_backup
    cp -r "${DB_PATH}" /opt/trilium_backup/
    rm -rf /opt/trilium
    msg_ok "Backed up Database"

    fetch_and_deploy_gh_release "Trilium" "TriliumNext/Trilium" "prebuild" "latest" "/opt/trilium" "TriliumNotes-Server-*linux-x64.tar.xz"

    msg_info "Restoring Database"
    mkdir -p "$(dirname "${DB_RESTORE_PATH}")"
    cp -r /opt/trilium_backup/$(basename "${DB_PATH}") "${DB_RESTORE_PATH}"
    msg_ok "Restored Database"

    msg_info "Cleaning up"
    rm -rf /opt/trilium_backup
    msg_ok "Cleaned"

    msg_info "Starting ${APP}"
    systemctl start trilium
    sleep 1
    msg_ok "Started ${APP}"
    msg_ok "Updated Successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
