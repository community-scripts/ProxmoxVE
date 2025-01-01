#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/glanceapp/glance

# App Default Values
APP="Glance"
var_tags="dashboard"
var_cpu="1"
var_ram="512"
var_disk="2"
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

  if [[ ! -f /etc/systemd/system/glance.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -s https://api.github.com/repos/glanceapp/glance/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop glance
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${RELEASE}"
    cd /opt
    wget -q https://github.com/glanceapp/glance/releases/download/v${RELEASE}/glance-linux-amd64.tar.gz
    rm -rf /opt/glance/glance
    tar -xzf glance-linux-amd64.tar.gz -C /opt/glance
    echo "${RELEASE}" >"/opt/${APP}_version.txt"
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start glance
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf /opt/glance-linux-amd64.tar.gz
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"