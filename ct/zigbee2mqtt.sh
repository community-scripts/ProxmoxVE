#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.zigbee2mqtt.io/

# App Default Values
APP="Zigbee2MQTT"
var_tags="smarthome;zigbee;mqtt"
var_cpu="2"
var_ram="1024"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="0"

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
  if [[ ! -d /opt/zigbee2mqtt ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/Koenkk/zigbee2mqtt/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop zigbee2mqtt
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    mkdir -p /opt/z2m_backup
    tar -czf /opt/z2m_backup/${APP}_backup_$(date +%Y%m%d%H%M%S).tar.gz -C /opt zigbee2mqtt &>/dev/null
    mv /opt/zigbee2mqtt/data /opt/z2m_backup
    msg_ok "Backup Created"

    msg_info "Updating ${APP} to v${RELEASE}"
    cd /opt
    wget -q "https://github.com/Koenkk/zigbee2mqtt/archive/refs/tags/${RELEASE}.zip"
    unzip -q ${RELEASE}.zip
    mv zigbee2mqtt-${RELEASE} /opt/zigbee2mqtt
    rm -rf /opt/zigbee2mqtt/data
    mv /opt/z2m_backup/data /opt/zigbee2mqtt
    cd /opt/zigbee2mqtt 
    pnpm install --frozen-lockfile &>/dev/null
    pnpm build &>/dev/null
    msg_info "Starting Service"
    systemctl start zigbee2mqtt
    msg_ok "Started Service"
    echo "${RELEASE}" >/opt/${APP}_version.txt
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9442${CL}"
