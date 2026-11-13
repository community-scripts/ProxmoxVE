#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TriliumNext/Trilium

APP="Trilium"
var_tags="${var_tags:-notes}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
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
  if [[ ! -d /opt/trilium && ! -f /etc/systemd/system/trilium.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "Trilium" "TriliumNext/Trilium" "" "" "v"; then
    # Notes live in Trilium's data directory, not in /opt/trilium: TRILIUM_DATA_DIR
    # when the service sets it, otherwise ~/trilium-data or ~/.local/share/trilium-data.
    DATA_DIR="$(systemctl show trilium -p Environment --value 2>/dev/null | tr ' ' '\n' | sed -n 's/^TRILIUM_DATA_DIR=//p' || true)"
    if [[ -z "$DATA_DIR" ]]; then
      DATA_DIR="/root/trilium-data"
      [[ -d "$DATA_DIR" ]] || DATA_DIR="/root/.local/share/trilium-data"
    fi
    if [[ "${DATA_DIR%/}" == "/opt/trilium" || "$DATA_DIR" == /opt/trilium/* ]]; then
      msg_error "Notes are stored in ${DATA_DIR}, which the update replaces. Move TRILIUM_DATA_DIR out of /opt/trilium first."
      exit 1
    fi
    DB_BACKUP="${DATA_DIR}/backup/backup-before-update.db"

    msg_info "Stopping Service"
    systemctl stop trilium
    msg_ok "Stopped Service"

    if [[ -f "${DATA_DIR}/document.db" ]]; then
      msg_info "Backing up Database"
      rm -f "$DB_BACKUP" "${DB_BACKUP}-wal" "${DB_BACKUP}-shm"
      # Trilium folds its -wal file into document.db when it stops; a leftover one
      # is copied as well, so the backup is complete even if it was killed.
      if mkdir -p "${DATA_DIR}/backup" && cp -a "${DATA_DIR}/document.db" "$DB_BACKUP" &&
        { [[ ! -f "${DATA_DIR}/document.db-wal" ]] || cp -a "${DATA_DIR}/document.db-wal" "${DB_BACKUP}-wal"; }; then
        msg_ok "Backed up Database to ${DB_BACKUP}"
      else
        rm -f "$DB_BACKUP" "${DB_BACKUP}-wal"
        systemctl start trilium
        msg_error "Database backup failed - update not started, Trilium restarted"
        exit 1
      fi
    else
      msg_warn "No database found in ${DATA_DIR}, nothing to back up"
    fi

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Trilium" "TriliumNext/Trilium" "prebuild" "latest" "/opt/trilium" "TriliumNotes-Server-*linux-$(arch_resolve "x64" "arm64").tar.xz" "v" || {
      systemctl start trilium
      msg_error "Update failed - the previous version is still installed and was restarted"
      exit 1
    }

    msg_info "Starting Service"
    systemctl start trilium
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
