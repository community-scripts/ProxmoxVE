#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://overseerr.dev/

# App Default Values
APP="Overseerr"
var_tags="media"
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
  if [[ ! -d /opt/overseerr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating $APP"
  systemctl stop overseerr
  cd /opt/overseerr
  output=$(git pull)
  git pull &>/dev/null
  if echo "$output" | grep -q "Already up to date."; then
    msg_ok " $APP is already up to date."
    systemctl start overseerr
    exit
  fi
  yarn install &>/dev/null
  yarn build &>/dev/null
  systemctl start overseerr
  msg_ok "Updated $APP"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5055${CL}"