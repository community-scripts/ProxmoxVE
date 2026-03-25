#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bluewave-labs/Checkmate

APP="Checkmate"
var_tags="${var_tags:-monitoring;uptime}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/checkmate ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "checkmate" "bluewave-labs/Checkmate"; then
    msg_info "Stopping Services"
    systemctl stop checkmate-server checkmate-client nginx
    msg_ok "Stopped Services"

    msg_info "Backing up Data"
    cp /opt/checkmate/server/.env /opt/checkmate_server.env.bak
    [ -f /opt/checkmate/client/.env.local ] && cp /opt/checkmate/client/.env.local /opt/checkmate_client.env.local.bak
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "checkmate" "bluewave-labs/Checkmate"

    msg_info "Updating Checkmate Server"
    cd /opt/checkmate/server
    $STD npm install
    if [ -f package.json ]; then
      grep -q '"build"' package.json && $STD npm run build || true
    fi
    msg_ok "Updated Checkmate Server"

    msg_info "Updating Checkmate Client"
    cd /opt/checkmate/client
    $STD npm install
    VITE_APP_API_BASE_URL="/api/v1" UPTIME_APP_API_BASE_URL="/api/v1" VITE_APP_LOG_LEVEL="warn" $STD npm run build
    msg_ok "Updated Checkmate Client"

    msg_info "Restoring Data"
    mv /opt/checkmate_server.env.bak /opt/checkmate/server/.env
    [ -f /opt/checkmate_client.env.local.bak ] && mv /opt/checkmate_client.env.local.bak /opt/checkmate/client/.env.local
    msg_ok "Restored Data"

    msg_info "Starting Services"
    systemctl start checkmate-server checkmate-client nginx
    msg_ok "Started Services"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
