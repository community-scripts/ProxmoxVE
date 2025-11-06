#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: HydroshieldMKII
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/HydroshieldMKII/Guardian

APP="Guardian"
var_tags="${var_tags:-media;monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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

  if [[ ! -d "/opt/guardian" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "guardian" "HydroshieldMKII/Guardian"; then
    msg_info "Stopping Services"
    systemctl stop guardian-backend guardian-frontend
    msg_ok "Stopped Services"

    if [[ -f "/opt/guardian/backend/plex-guard.db" ]]; then
      msg_info "Backing up Database"
      cp "/opt/guardian/backend/plex-guard.db" "/tmp/plex-guard.db.backup"
      msg_ok "Backed up Database"
    fi

    [[ -f "/opt/guardian/.env" ]] && cp "/opt/guardian/.env" "/opt"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "guardian" "HydroshieldMKII/Guardian" "tarball" "latest" "/opt/guardian"
    [[ -f "/opt/.env" ]] && mv "/opt/.env" "/opt/guardian"

    if [[ -f "/tmp/plex-guard.db.backup" ]]; then
      msg_info "Restoring Database"
      cp "/tmp/plex-guard.db.backup" "/opt/guardian/backend/plex-guard.db"
      rm "/tmp/plex-guard.db.backup"
      msg_ok "Restored Database"
    fi

    msg_info "Updating Guardian"
    cd /opt/guardian/backend
    $STD npm ci
    $STD npm run build

    cd /opt/guardian/frontend
    $STD npm ci
    export DEPLOYMENT_MODE=standalone
    $STD npm run build
    msg_ok "Updated Guardian"

    msg_info "Starting Services"
    systemctl start guardian-backend guardian-frontend
    msg_ok "Started Services"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
