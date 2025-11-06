#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://listmonk.app/

APP="listmonk"
var_tags="${var_tags:-newsletter}"
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
  if [[ ! -f /etc/systemd/system/listmonk.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "listmonk" "knadh/listmonk"; then
    msg_info "Stopping Service"
    systemctl stop listmonk
    msg_ok "Stopped Service"

    msg_info "Backing up data"
    mv /opt/listmonk/ /opt/listmonk-backup
    msg_ok "Backed up data"

    fetch_and_deploy_gh_release "listmonk" "knadh/listmonk" "prebuild" "latest" "/opt/listmonk" "listmonk*linux_amd64.tar.gz"

    msg_info "Configuring listmonk"
    mv /opt/listmonk-backup/config.toml /opt/listmonk/config.toml
    mv /opt/listmonk-backup/uploads /opt/listmonk/uploads
    $STD /opt/listmonk/listmonk --upgrade --yes --config /opt/listmonk/config.toml
    msg_ok "Configured listmonk"

    msg_info "Starting Service"
    systemctl start listmonk
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf /opt/listmonk-backup/
    msg_ok "Cleaned"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000${CL}"
