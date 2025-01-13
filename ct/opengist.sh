#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Jonathan (jd-apprentice)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://opengist.io/

# App Default Values
APP="Opengist"
var_tags="development"
var_cpu="1"
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
  if [[ ! -d /opt/opengist ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Stopping Service"
  systemctl stop opengist.service
  msg_ok "Stopped Service"
  apt-get update &>/dev/null
  apt-get upgrade &>/dev/null
  RELEASE=$(curl -s https://api.github.com/repos/thomiceli/opengist/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Updating ${APP} to v${RELEASE}"
    cd /opt
    wget -qO "https://github.com/thomiceli/opengist/releases/download/v${RELEASE}/opengist${RELEASE}-linux-amd64.tar.gz"
    rm -rf /opt/opengist
    tar -xzf opengist${RELEASE}-linux-amd64.tar.gz
    chmod +x /opt/opengist/opengist
    echo "${RELEASE}" >"/opt/${APP}_version.txt"
    rm -rf /opt/opengist${RELEASE}-linux-amd64.tar.gz
    apt-get -y autoremove &>/dev/null
    apt-get -y autoclean &>/dev/null
    msg_ok "Updated ${APP} LXC"

    msg_info "Starting Service"
    systemctl start opengist.service
    msg_ok "Started Service"
    
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6157${CL}"
