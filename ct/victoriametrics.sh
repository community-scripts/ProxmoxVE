#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: Denys Holius https://github.com/denisgolius
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://victoriametrics.com/

# App Default Values
APP="VictoriaMetrics"
var_tags="monitoring"
var_cpu="1"
var_ram="2048"
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
  if [[ ! -f /etc/systemd/system/victoriametrics.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop victoriametrics
    msg_ok "Stopped ${APP}"
    msg_info "Updating ${APP} to ${RELEASE}"
    mkdir -p /opt/victoriametrics
    wget -q https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${RELEASE}/victoria-metrics-linux-amd64-${RELEASE}.tar.gz
    tar -xf --delete victoria-metrics-linux-amd64-${RELEASE}.tar.gz -C /opt/victoriametrics
    rm -rf victoria-metrics-linux-amd64-${RELEASE}.tar.gz
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting ${APP}"
    systemctl start victoriametrics
    msg_ok "Started ${APP}"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8429${CL}"