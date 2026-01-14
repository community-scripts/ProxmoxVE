#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: tomfrenzel
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/thedevs-network/kutt

APP="Kutt"
var_tags="${var_tags:-sharing}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-2}"
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

  if [[ ! -d /opt/kutt ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "kutt" "thedevs-network/kutt"; then
    msg_info "Stopping services"
    systemctl stop kutt
    msg_ok "Stopped services"

    msg_info "Backing up data"
    mkdir -p /opt/kutt-backup
    [ -d /opt/kutt/custom ] && cp -r /opt/kutt/custom /opt/kutt-backup/
    [ -d /opt/kutt/db ] && cp -r /opt/kutt/db /opt/kutt-backup/
    cp /opt/kutt/.env /opt/kutt-backup/
    msg_ok "Backed up data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "kutt" "thedevs-network/kutt" "tarball" "latest"

    msg_info "Restoring data"
    [ -d /opt/kutt-backup/custom ] && cp -r /opt/kutt-backup/custom /opt/kutt/
    [ -d /opt/kutt-backup/db ] && cp -r /opt/kutt-backup/db /opt/kutt/
    [ -f /opt/kutt-backup/.env ] && cp /opt/kutt-backup/.env /opt/kutt/
    rm -rf /opt/kutt-backup
    msg_ok "Restored data"

    msg_info "Configuring Kutt"
    cd /opt/kutt
    $STD npm install
    $STD npm run migrate
    msg_ok "Configured Kutt"

    msg_info "Starting services"
    systemctl start kutt
    msg_ok "Started services"
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
echo -e "${TAB}${GATEWAY}${BGN}https://${IP} or https://<your-Kutt-domain>${CL}"
