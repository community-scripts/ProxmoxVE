#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://adventurelog.app/

# App Default Values
APP="AdventureLog"
var_tags="traveling"
var_disk="7"
var_cpu="2"
var_ram="2048"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
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
    cp /opt/adventurelog/backend/server/.env /opt/server.env
    cp /opt/adventurelog/frontend/.env /opt/frontend.env
    wget -q "https://github.com/seanmorley15/AdventureLog/archive/refs/tags/v${RELEASE}.zip"
    unzip -q v${RELEASE}.zip
    mv AdventureLog-${RELEASE} /opt/adventurelog
    mv /opt/server.env /opt/adventurelog/backend/server/.env
    cd /opt/adventurelog/backend/server
    pip install --upgrade pip &>/dev/null
    pip install -r requirements.txt &>/dev/null
    python3 manage.py collectstatic --noinput &>/dev/null
    python3 manage.py migrate &>/dev/null

    mv /opt/frontend.env /opt/adventurelog/frontend/.env
    cd /opt/adventurelog/frontend
    pnpm install &>/dev/null
    pnpm run build &>/dev/null
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP}"

    msg_info "Starting Services"
    systemctl start adventurelog-backend
    systemctl start adventurelog-frontend
    msg_ok "Started Services"

    msg_info "Cleaning Up"
    rm -rf v${RELEASE}.zip
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