#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://adventurelog.app/

APP="AdventureLog"
var_tags="traveling"
var_disk="7"
var_cpu="2"
var_ram="2048"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/adventurelog ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/seanmorley15/AdventureLog/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Services"
    systemctl stop adventurelog-backend
    systemctl stop adventurelog-frontend
    msg_ok "Services Stopped"

    msg_info "Updating ${APP} to ${RELEASE}"
    mv /opt/adventurelog/ /opt/adventurelog-backup/
    wget -qO /opt/v${RELEASE}.zip "https://github.com/seanmorley15/AdventureLog/archive/refs/tags/v${RELEASE}.zip"
    unzip -q /opt/v${RELEASE}.zip -d /opt/
    mv /opt/AdventureLog-${RELEASE} /opt/adventurelog

    mv /opt/adventurelog-backup/backend/server/.env /opt/adventurelog/backend/server/.env
    mv /opt/adventurelog-backup/backend/server/media /opt/adventurelog/backend/server/media
    cd /opt/adventurelog/backend/server
    $STD pip install --upgrade pip
    $STD pip install -r requirements.txt
    $STD python3 manage.py collectstatic --noinput
    $STD python3 manage.py migrate

    mv /opt/adventurelog-backup/frontend/.env /opt/adventurelog/frontend/.env
    cd /opt/adventurelog/frontend
    $STD pnpm install
    $STD pnpm run build
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP}"

    msg_info "Starting Services"
    systemctl start adventurelog-backend
    systemctl start adventurelog-frontend
    msg_ok "Started Services"

    msg_info "Cleaning Up"
    rm -rf /opt/v${RELEASE}.zip
    rm -rf /opt/adventurelog-backup
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
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
