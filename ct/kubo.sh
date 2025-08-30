#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author: ulmentflam
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ipfs/kubo

APP="Kubo"
var_tags="${var_tags:-sharing}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-4}"
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
  if [[ ! -f /usr/local/kubo/ipfs ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "kubo" "ipfs/kubo"; then
    msg_info "Stopping service"
    systemctl stop ipfs
    msg_ok "Stopped service"

    fetch_and_deploy_gh_release "kubo" "ipfs/kubo" "prebuild" "latest" "/usr/local/kubo" "kubo*linux-amd64.tar.gz"

    msg_info "Starting service"
    systemctl start ipfs
    msg_ok "Service started"
    msg_ok "Updated successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5001/webui${CL}"
