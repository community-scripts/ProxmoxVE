#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://uptime.kuma.pet/

# App Default Values
APP="Uptime Kuma"
var_tags="analytics;monitoring"
var_cpu="1"
var_ram="1024"
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
  if [[ ! -d /opt/uptime-kuma ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ "$(node -v | cut -d 'v' -f 2)" == "18."* ]]; then
    if ! command -v npm >/dev/null 2>&1; then
      echo "Installing NPM..."
      apt-get install -y npm >/dev/null 2>&1
      echo "Installed NPM..."
    fi
  fi
  LATEST=$(curl -sL https://api.github.com/repos/louislam/uptime-kuma/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
  msg_info "Stopping ${APP}"
  sudo systemctl stop uptime-kuma &>/dev/null
  msg_ok "Stopped ${APP}"

  cd /opt/uptime-kuma

  msg_info "Pulling ${APP} ${LATEST}"
  git fetch --all &>/dev/null
  git checkout $LATEST --force &>/dev/null
  msg_ok "Pulled ${APP} ${LATEST}"

  msg_info "Updating ${APP} to ${LATEST}"
  npm install --production &>/dev/null
  npm run download-dist &>/dev/null
  msg_ok "Updated ${APP}"

  msg_info "Starting ${APP}"
  sudo systemctl start uptime-kuma &>/dev/null
  msg_ok "Started ${APP}"
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3001${CL}"
