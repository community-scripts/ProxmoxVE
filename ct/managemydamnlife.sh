#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/intri-in/manage-my-damn-life-nextjs

APP="Manage My Damn Life"
var_tags="${var_tags:-calendar;tasks}"
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

  if [[ ! -d /opt/mmdl ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/intri-in/manage-my-damn-life-nextjs/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat /opt/mmdl_version.txt)" ]] || [[ ! -f /opt/mmdl_version.txt ]]; then
    msg_info "Stopping $APP"
    systemctl stop mmdl
    msg_ok "Stopped $APP"

    msg_info "Creating Backup"
    cp /opt/mmdl/.env /opt/mmdl.env
    msg_ok "Backup Created"

    msg_info "Updating $APP to v${RELEASE}"
    curl -fsSLO "https://github.com/intri-in/manage-my-damn-life-nextjs/archive/refs/tags/v${RELEASE}.zip"
    rm -r /opt/mmdl
    unzip -q v"$RELEASE".zip
    mv manage-my-damn-life-nextjs-"$RELEASE"/ /opt/mmdl
    mv /opt/mmdl.env /opt/mmdl/.env
    cd /opt/mmdl
    $STD npm install
    $STD npm run migrate
    $STD npm run build
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting $APP"
    systemctl start mmdl
    msg_ok "Started $APP"

    msg_info "Cleaning Up"
    rm -f ~/v"$RELEASE".zip
    msg_ok "Cleanup Completed"

    # Last Action
    echo "$RELEASE" >/opt/mmdl_version.txt
    msg_ok "Update Successful"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
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
