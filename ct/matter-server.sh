#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/matter-js/python-matter-server

APP="Matter-Server"
var_tags="${var_tags:-matter;iot;smart-home}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/matter-server ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "matter-server" "matter-js/python-matter-server"; then
    msg_info "Stopping Service"
    systemctl stop matter-server
    msg_ok "Stopped Service"

    msg_info "Updating Matter Server"
    MATTER_VERSION=$(get_latest_github_release "matter-js/python-matter-server")
    $STD uv pip install --python /opt/matter-server/.venv/bin/python --upgrade "python-matter-server[server]==${MATTER_VERSION}"
    echo "${MATTER_VERSION}" >~/.matter-server
    msg_ok "Updated Matter Server"

    fetch_and_deploy_gh_release "chip-ota-provider-app" "home-assistant-libs/matter-linux-ota-provider" "singlefile" "latest" "/usr/local/bin" "chip-ota-provider-app-x86-64"

    msg_info "Starting Service"
    systemctl start matter-server
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
echo -e "${INFO}${YW} Matter Server WebSocket API is running on port 5580.${CL}"
echo -e "${TAB}${GATEWAY}${BGN}ws://${IP}:5580/ws${CL}"
