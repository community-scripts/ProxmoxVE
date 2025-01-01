#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author: Scorpoon
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/revenz/Fenrus

# App Default Values
APP="Fenrus"
var_tags="dashboard"
var_cpu="1"
var_ram="512"
var_disk="4"
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
  if [[ ! -d /opt/${APP} ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_error "There is currently no update path available."
  exit
  msg_info "Updating ${APP}"
  systemctl stop ${APP}
  git clone https://github.com/revenz/Fenrus.git
  cd Fenrus || exit
  gitVersionNumber=$(git rev-parse HEAD)

  if [[ "${gitVersionNumber}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    mkdir /opt/fenrus-data-backup
    cp -r "/opt/${APP}/data/" /opt/fenrus-data-backup/data
    if [[ ! -d /opt/fenrus-data-backup/data ]]; then
      msg_error "Backup of data folder failed! exiting..."
      rm -r /opt/fenrus-data-backup/
      exit
    fi
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    dotnet publish -c Release -o "/opt/${APP}/" Fenrus.csproj
    cp -r /opt/fenrus-data-backup/data/ "/opt/${APP}/"
    echo "${gitVersionNumber}" >"/opt/${APP}_version.txt"
    rm -r /opt/fenrus-data-backup/
    msg_ok "Updated $APP"
  else
    msg_ok "No update required. ${APP} is already up to date"
  fi
  cd ..
  rm -r Fenrus/

  systemctl start ${APP}
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
