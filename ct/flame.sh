#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pawelmalak/flame

APP="Flame"
var_tags="${var_tags:-dashboard;startpage}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/flame ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "flame" "pawelmalak/flame"; then
    msg_info "Stopping Service"
    systemctl stop flame
    msg_ok "Stopped Service"

    create_backup /opt/flame/.env \
                  /opt/flame/data

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "flame" "pawelmalak/flame" "tarball"

    restore_backup

    msg_info "Rebuilding Application"
    cd /opt/flame
    mkdir -p data public
    $STD npm install --production
    cd /opt/flame/client
    $STD npm install --production
    $STD npm run build
    cd /opt/flame
    cp -r client/build/. public/
    msg_ok "Rebuilt Application"

    msg_info "Starting Service"
    systemctl start flame
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5005${CL}"
