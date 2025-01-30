#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: havardthom
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openwebui.com/

# App Default Values
APP="Open WebUI"
var_tags="ai;interface"
var_cpu="4"
var_ram="4096"
var_disk="16"
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
  if [[ ! -d /opt/open-webui ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP} (Patience)"
  cd /opt/open-webui
  output=$(git pull --no-rebase)
  if echo "$output" | grep -q "Already up to date."; then
    msg_ok "$APP is already up to date."
    exit
  fi
  systemctl stop open-webui.service
  npm install &>/dev/null
  export NODE_OPTIONS="--max-old-space-size=3584"
  npm run build &>/dev/null
  cd ./backend
  pip install -r requirements.txt -U &>/dev/null
  systemctl start open-webui.service
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"