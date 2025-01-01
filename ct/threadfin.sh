#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Threadfin/Threadfin

# App Default Values
APP="Threadfin"
var_tags="media"
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
  if [[ ! -d /opt/threadfin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating $APP"
  systemctl stop threadfin.service
  wget -q -O /opt/threadfin/threadfin 'https://github.com/Threadfin/Threadfin/releases/latest/download/Threadfin_linux_amd64'
  chmod +x /opt/threadfin/threadfin
  systemctl start threadfin.service
  msg_ok "Updated $APP"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:34400/web${CL}"