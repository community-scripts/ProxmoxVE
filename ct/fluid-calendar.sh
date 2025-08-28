#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://fluidcalendar.com

APP="fluid-calendar"
var_tags="${var_tags:-calendar,tasks}"
var_cpu="${var_cpu:-3}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-7}"
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

  if [[ ! -d /opt/fluid-calendar ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "fluid-calendar" "dotnetfactory/fluid-calendar"; then
    msg_info "Stopping $APP"
    systemctl stop fluid-calendar
    msg_ok "Stopped $APP"

    cp /opt/fluid-calendar/.env /opt/fluid.env
    rm -rf /opt/fluid-calendar
    fetch_and_deploy_gh_release "fluid-calendar" "dotnetfactory/fluid-calendar"

    msg_info "Updating $APP"
    mv /opt/fluid.env /opt/fluid-calendar/.env
    cd /opt/fluid-calendar
    export NEXT_TELEMETRY_DISABLED=1
    $STD npm install --legacy-peer-deps
    $STD npm run prisma:generate
    $STD npx prisma migrate deploy
    $STD npm run build:os
    msg_ok "Updated $APP"

    msg_info "Starting $APP"
    systemctl start fluid-calendar
    msg_ok "Started $APP"
    msg_ok "Update Successful"
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
