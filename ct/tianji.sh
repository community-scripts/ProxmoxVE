#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tianji.msgbyte.com/

# App Default Values
APP="Tianji"
var_tags="monitoring"
var_cpu="4"
var_ram="4096"
var_disk="12"
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
  if [[ ! -d /opt/tianji ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/msgbyte/tianji/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP} Service"
    systemctl stop tianji
    msg_ok "Stopped ${APP} Service"
    msg_info "Updating ${APP} to ${RELEASE}"
    cd /opt
    cp /opt/tianji/src/server/.env /opt/.env
    mv /opt/tianji /opt/tianji_bak
    wget -q "https://github.com/msgbyte/tianji/archive/refs/tags/v${RELEASE}.zip"
    unzip -q v${RELEASE}.zip
    mv tianji-${RELEASE} /opt/tianji
    cd tianji
    pnpm install --filter @tianji/client... --config.dedupe-peer-dependents=false --frozen-lockfile >/dev/null 2>&1
    pnpm build:static >/dev/null 2>&1
    pnpm install --filter @tianji/server... --config.dedupe-peer-dependents=false >/dev/null 2>&1
    mkdir -p ./src/server/public >/dev/null 2>&1
    cp -r ./geo ./src/server/public >/dev/null 2>&1
    pnpm build:server >/dev/null 2>&1
    mv /opt/.env /opt/tianji/src/server/.env
    cd src/server
    pnpm db:migrate:apply >/dev/null 2>&1
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"
    msg_info "Starting ${APP}"
    systemctl start tianji
    msg_ok "Started ${APP}"
    msg_info "Cleaning up"
    rm -R /opt/v${RELEASE}.zip
    rm -rf /opt/tianji_bak
    rm -rf /opt/tianji/src/client
    rm -rf /opt/tianji/website
    rm -rf /opt/tianji/reporter
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required.  ${APP} is already at ${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:12345${CL}"