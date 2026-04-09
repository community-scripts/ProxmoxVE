#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Hotfirenet
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/note-sx/server

APP="NoteSX"
var_tags="${var_tags:-notes;sharing}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
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

  if [[ ! -d /opt/notesx ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "notesx" "note-sx/server"; then
    msg_info "Stopping Service"
    systemctl stop notesx
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp /opt/notesx/app/.env /opt/notesx_env_backup
    cp -r /opt/notesx/db /opt/notesx_db_backup
    cp -r /opt/notesx/userfiles /opt/notesx_userfiles_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "notesx" "note-sx/server" "tarball" "latest" "/opt/notesx"

    msg_info "Rebuilding ${APP}"
    cd /opt/notesx/app
    $STD npm install --omit=dev
    $STD npx tsc --noCheck
    msg_ok "Rebuilt ${APP}"

    msg_info "Restoring Data"
    cp /opt/notesx_env_backup /opt/notesx/app/.env
    cp -r /opt/notesx_db_backup/. /opt/notesx/db
    cp -r /opt/notesx_userfiles_backup/. /opt/notesx/userfiles
    rm -f /opt/notesx_env_backup
    rm -rf /opt/notesx_db_backup /opt/notesx_userfiles_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start notesx
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
