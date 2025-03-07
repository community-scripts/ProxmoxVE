#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2025
# License: MIT
# Source: https://github.com/ThePhaseless/Byparr

APP="Byparr"
var_tags="proxy"
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
  if [[ ! -f /etc/systemd/system/byparr.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  
  msg_info "Updating $APP LXC"
  cd /opt/byparr
  
  # Pull latest changes
  git pull
  
  # Run test to ensure everything works with new version
  ./test-script.sh
  
  if [ $? -ne 0 ]; then
    msg_error "Tests failed after update. Rolling back."
    git reset --hard HEAD@{1}
    systemctl restart byparr.service
    exit 1
  fi
  
  # Restart service to apply changes
  systemctl restart byparr.service
  msg_ok "Updated $APP LXC"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8191${CL}"