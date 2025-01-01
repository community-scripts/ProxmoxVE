#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://homarr.dev/

# App Default Values
APP="Homarr"
var_tags="arr;dashboard"
var_cpu="2"
var_ram="2048"
var_disk="8"
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
  if [[ ! -d /opt/homarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/ajnart/homarr/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Services"
    systemctl stop homarr
    msg_ok "Services Stopped"

    msg_info "Backing up Data"
    mkdir -p /opt/homarr-data-backup
    cp /opt/homarr/.env /opt/homarr-data-backup/.env
    cp /opt/homarr/database/db.sqlite /opt/homarr-data-backup/db.sqlite
    cp -r /opt/homarr/data/configs /opt/homarr-data-backup/configs
    msg_ok "Backed up Data"

    msg_info "Updating ${APP} to ${RELEASE}"
    wget -q "https://github.com/ajnart/homarr/archive/refs/tags/v${RELEASE}.zip"
    unzip -q v${RELEASE}.zip
    rm -rf v${RELEASE}.zip
    rm -rf /opt/homarr
    mv homarr-${RELEASE} /opt/homarr
    mv /opt/homarr-data-backup/.env /opt/homarr/.env
    cd /opt/homarr
    yarn install &>/dev/null
    yarn build &>/dev/null
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP}"

    msg_info "Restoring Data"
    rm -rf /opt/homarr/data/configs
    mv /opt/homarr-data-backup/configs /opt/homarr/data/configs
    mv /opt/homarr-data-backup/db.sqlite /opt/homarr/database/db.sqlite
    yarn db:migrate &>/dev/null
    rm -rf /opt/homarr-data-backup
    msg_ok "Restored Data"

    msg_info "Starting Services"
    systemctl start homarr
    msg_ok "Started Services"
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