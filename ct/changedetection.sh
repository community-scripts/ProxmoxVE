#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/develop/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://changedetection.io/

# App Default Values
APP="Change Detection"
var_tags="monitoring;crawler"
var_cpu="2"
var_ram="1024"
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
  if [[ ! -f /etc/systemd/system/changedetection.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP} LXC"
  if ! dpkg -s libjpeg-dev >/dev/null 2>&1; then
    apt-get update
    apt-get install -y libjpeg-dev
  fi
  pip3 install changedetection.io --upgrade &>/dev/null
  pip3 install playwright --upgrade &>/dev/null
  if [[ -f /etc/systemd/system/browserless.service ]]; then
    git -C /opt/browserless/ fetch --all &>/dev/null
    git -C /opt/browserless/ reset --hard origin/main &>/dev/null
    npm update --prefix /opt/browserless &>/dev/null
    npm run build --prefix /opt/browserless &>/dev/null
    npm run build:function --prefix /opt/browserless &>/dev/null
    npm prune production --prefix /opt/browserless &>/dev/null
    systemctl restart browserless
  else
    msg_error "No Browserless Installation Found!"
  fi
  systemctl restart changedetection
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"