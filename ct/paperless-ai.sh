#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/clusterzx/paperless-ai

APP="Paperless-AI"
var_tags="ai;document"
var_cpu="2"
var_ram="2048"
var_disk="5"
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
  if [[ ! -d /opt/paperless-ai ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/clusterzx/paperless-ai/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Stopping $APP"
    systemctl stop paperless-ai
    msg_ok "Stopped $APP"

    msg_info "Updating $APP to v${RELEASE}"
    cd /opt
    mv /opt/paperless-ai /opt/paperless-ai_bak
    wget -q "https://github.com/clusterzx/paperless-ai/archive/refs/tags/v${RELEASE}.zip"
    unzip -q v${RELEASE}.zip
    mv paperless-ai-${RELEASE} /opt/paperless-ai
    mkdir -p /opt/paperless-ai/data
    cp -a /opt/paperless-ai_bak/data/. /opt/paperless-ai/data/
    cd /opt/paperless-ai
    npm install &>/dev/null
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting $APP"
    systemctl start paperless-ai
    msg_ok "Started $APP"

    msg_info "Cleaning Up"
    rm -rf /opt/v${RELEASE}.zip
    rm -rf /opt/paperless-ai_bak
    msg_ok "Cleanup Completed"
    msg_ok "Update Successful"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}
start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
