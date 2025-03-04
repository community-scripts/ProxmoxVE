#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://magicmirror.builders/

APP="MagicMirror"
var_tags="smarthome"
var_cpu="1"
var_ram="512"
var_disk="3"
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
  if [[ ! -d /opt/magicmirror ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/MagicMirrorOrg/MagicMirror/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]]; then touch /opt/${APP}_version.txt; fi
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop magicmirror
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${RELEASE}"
    $STD apt-get update
    $STD apt-get upgrade -y
    rm -rf /opt/magicmirror-backup
    mkdir /opt/magicmirror-backup
    cp /opt/magicmirror/config/config.js /opt/magicmirror-backup
    if [[ -f /opt/magicmirror/css/custom.css ]]; then
      cp /opt/magicmirror/css/custom.css /opt/magicmirror-backup
    fi
    cp -r /opt/magicmirror/modules /opt/magicmirror-backup
    temp_file=$(mktemp)
    wget -q "https://github.com/MagicMirrorOrg/MagicMirror/archive/refs/tags/v${RELEASE}.tar.gz" -O "$temp_file"
    tar -xzf "$temp_file"
    rm -rf /opt/magicmirror
    mv MagicMirror-${RELEASE} /opt/magicmirror
    cd /opt/magicmirror
    $STD npm run install-mm
    cp /opt/magicmirror-backup/config.js /opt/magicmirror/config/
    if [[ -f /opt/magicmirror-backup/custom.css ]]; then
      cp /opt/magicmirror-backup/custom.css /opt/magicmirror/css/
    fi
    echo "${RELEASE}" >"/opt/${APP}_version.txt"
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start magicmirror
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -f $temp_file
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
