#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mafl.hywax.space/

APP="Mafl"
var_tags="${var_tags:-dashboard}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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
  if [[ ! -d /opt/mafl ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "mafl" "hywax/mafl"; then
    msg_info "Stopping Mafl service"
    systemctl stop mafl
    msg_ok "Service stopped"

    msg_info "Backing up data"
    mkdir -p /opt/mafl-backup/data
    mv /opt/mafl/data /opt/mafl-backup/data
    rm -rf /opt/mafl
    msg_ok "Backup complete"

    fetch_and_deploy_gh_release "mafl" "hywax/mafl"

    msg_info "Updating Mafl"
    cd /opt/mafl
    $STD yarn install
    $STD yarn build
    mv /opt/mafl-backup/data /opt/mafl/data
    msg_ok "Mafl updated"

    msg_info "Starting Service"
    systemctl start mafl
    msg_ok "Service started"
    msg_ok "Update successfully"
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
