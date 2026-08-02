#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gamosoft/NoteDiscovery

APP="NoteDiscovery"
var_tags="${var_tags:-notes;wiki;knowledge-base}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
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

  if [[ ! -d /opt/notediscovery ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "notediscovery" "gamosoft/NoteDiscovery"; then
    msg_info "Stopping Service"
    systemctl stop notediscovery
    msg_ok "Stopped Service"

    create_backup /opt/notediscovery/data /opt/notediscovery/config.yaml

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "notediscovery" "gamosoft/NoteDiscovery" "tarball"

    msg_info "Syncing Dependencies"
    cd /opt/notediscovery
    $STD uv sync --no-dev
    msg_ok "Synced Dependencies"

    restore_backup

    msg_info "Starting Service"
    systemctl start notediscovery
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
