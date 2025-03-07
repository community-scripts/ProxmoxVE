#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Your Name Here | Co-Author: Another Name
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/byparr/byparr

APP="Byparr"
var_tags="automatic-rarbg-replacement"
var_cpu="2"
var_ram="2048"
var_disk="4"
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
  if [[ ! -d /Byparr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  
  cd /Byparr
  CURRENT_VERSION=$(git rev-parse HEAD)
  git fetch
  LATEST_VERSION=$(git rev-parse origin/main)
  
  if [[ "${CURRENT_VERSION}" != "${LATEST_VERSION}" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Updating ${APP}"
    git pull
    uv sync --group test
    echo "${LATEST_VERSION}" > /opt/${APP}_version.txt
    msg_ok "Updated ${APP}"
  else
    msg_ok "No update required. ${APP} is already at the latest version"
  fi
  exit
}

start
build_container
description

# Ensure IP variable is correctly set
IP=$(pct exec "$CTID" ip a s dev eth0 | sed -n 's/.*inet \([0-9\.]*\).*/\1/p')

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
echo -e "${INFO}${YW} Default login credentials:${CL}"
echo -e "${TAB}${YW}Username: root${CL}"
echo -e "${TAB}${YW}Password: root${CL}"