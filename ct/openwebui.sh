#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: havardthom
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openwebui.com/

APP="Open WebUI"
var_tags="ai;interface"
var_cpu="4"
var_ram="4096"
var_disk="16"
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
  if [[ ! -d /opt/open-webui ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP} (Patience)"
  cd /opt/open-webui
  mkdir -p /opt/open-webui-backup
  cp -rf /opt/open-webui/backend/data /opt/open-webui-backup
  git add -A
  $STD git stash
  $STD git reset --hard
  output=$(git pull --no-rebase)
  if echo "$output" | grep -q "Already up to date."; then
    msg_ok "$APP is already up to date."
    exit
  fi
  systemctl stop open-webui.service
  $STD npm install
  export NODE_OPTIONS="--max-old-space-size=3584"
  $STD npm run build
  cd ./backend
  $STD pip install -r requirements.txt -U
  cp -rf /opt/open-webui-backup/* /opt/open-webui/backend
  if git stash list | grep -q 'stash@{'; then
    $STD git stash pop
  fi
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
