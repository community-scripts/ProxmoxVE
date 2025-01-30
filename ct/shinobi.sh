#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://shinobi.video/

# App Default Values
APP="Shinobi"
var_tags="nvr"
var_cpu="2"
var_ram="2048"
var_disk="8"
var_os="ubuntu"
var_version="22.04"
var_unprivileged="0"

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
  if [[ ! -d /opt/Shinobi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating Shinobi LXC"
  cd /opt/Shinobi
  sh UPDATE.sh
  pm2 flush
  pm2 restart camera
  pm2 restart cron
  msg_ok "Updated Shinobi LXC"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080/super${CL}"