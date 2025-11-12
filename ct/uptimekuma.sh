#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://uptime.kuma.pet/

APP="Uptime Kuma"
var_tags="${var_tags:-analytics;monitoring}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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
  if [[ ! -d /opt/uptime-kuma ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" setup_nodejs

  if check_for_gh_release "uptime-kuma" "louislam/uptime-kuma"; then
    msg_info "Stopping Service"
    systemctl stop uptime-kuma
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "uptime-kuma" "louislam/uptime-kuma" "tarball"

    msg_info "Updating Uptime Kuma"
    cd /opt/uptime-kuma
    $STD npm install --omit dev
    $STD npm run download-dist
    msg_ok "Updated Uptime Kuma"

    msg_info "Starting Service"
    systemctl start uptime-kuma
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3001${CL}"
