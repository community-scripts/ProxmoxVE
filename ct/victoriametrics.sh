#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/VictoriaMetrics/VictoriaMetrics

APP="VictoriaMetrics"
var_tags="database"
var_cpu="2"
var_ram="2048"
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
  if [[ ! -d /opt/victoriametrics ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping $APP"
    systemctl stop victoriametrics
    msg_ok "Stopped $APP"
    
    msg_info "Updating ${APP} to v${RELEASE}"
    temp_dir=$(mktemp -d)
    cd $temp_dir
    wget -q https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${RELEASE}/victoria-metrics-linux-amd64-v${RELEASE}.tar.gz
    wget -q https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${RELEASE}/vmutils-linux-amd64-v${RELEASE}.tar.gz
    find /opt/victoriametrics -maxdepth 1 -type f -executable -delete
    tar -xf victoria-metrics-linux-amd64-v${RELEASE}.tar.gz -C /opt/victoriametrics
    tar -xf vmutils-linux-amd64-v${RELEASE}.tar.gz -C /opt/victoriametrics
    chmod +x /opt/victoriametrics/*
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to v${RELEASE}"
    
    msg_info "Starting $APP"
    systemctl start victoriametrics
    msg_ok "Started $APP"
    
    msg_info "Cleaning Up"
    rm -rf $temp_dir
    msg_ok "Cleaned"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8428/vmui${CL}"
