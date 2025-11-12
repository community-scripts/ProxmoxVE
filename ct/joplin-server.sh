#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://joplinapp.org/

APP="Joplin-Server"
var_tags="${var_tags:-notes}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
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
  if [[ ! -d /opt/joplin-server ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "joplin-server" "laurent22/joplin"; then
    msg_info "Stopping Services"
    systemctl stop joplin-server
    msg_ok "Stopped Services"

    fetch_and_deploy_gh_release "joplin-server" "laurent22/joplin" "tarball" "latest"

    msg_info "Updating Joplin-Server"
    cd /opt/joplin-server
    sed -i "/onenote-converter/d" packages/lib/package.json
    $STD yarn config set --home enableTelemetry 0
    export BUILD_SEQUENCIAL=1
    $STD yarn install --inline-builds
    msg_ok "Updated Joplin-Server"

    msg_info "Starting Services"
    systemctl start joplin-server
    msg_ok "Started Services"
    msg_ok "Updated Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:22300${CL}"
