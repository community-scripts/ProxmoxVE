#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://triliumnext.github.io/Docs/

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
  if [[ ! -f /opt/${APP}_version.txt ]]; then touch /opt/${APP}_version.txt; fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/TriliumNext/Notes/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
 if [[ "v${RELEASE}" != "$(cat /opt/${APP}_version.txt 2>/dev/null)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
 
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

  msg_info "Updating to ${RELEASE}"
  mkdir -p /opt/trilium_backup
  cp -r "${DB_PATH}" /opt/trilium_backup/
  rm -rf /opt/trilium
  cd /tmp
  curl -fsSL "https://github.com/TriliumNext/trilium/releases/download/v${RELEASE}/TriliumNextNotes-Server-v${RELEASE}-linux-x64.tar.xz" -o "TriliumNextNotes-Server-v${RELEASE}-linux-x64.tar.xz"
  tar -xf "TriliumNextNotes-Server-v${RELEASE}-linux-x64.tar.xz"
  mv "TriliumNextNotes-Server-${RELEASE}-linux-x64" /opt/trilium

  # Restore database
  mkdir -p "$(dirname "${DB_RESTORE_PATH}")"
  cp -r /opt/trilium_backup/$(basename "${DB_PATH}") "${DB_RESTORE_PATH}"

  echo "v${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated to ${RELEASE}"

  msg_info "Cleaning up"
  rm -rf "/tmp/TriliumNextNotes-Server-${RELEASE}-linux-x64.tar.xz"
  rm -rf /opt/trilium_backup
  msg_ok "Cleaned"

  msg_info "Starting ${APP}"
  systemctl start trilium
  sleep 1
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
