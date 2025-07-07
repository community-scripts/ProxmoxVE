#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: rcourtman
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rcourtman/Pulse

APP="Pulse"
var_tags="${var_tags:-monitoring,proxmox}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ -d /opt/pulse-monitor ]]; then
  msg_error "An old installation was detected. Please recreate the LXC from scratch (https://github.com/community-scripts/ProxmoxVE/pull/4848)"
  exit 1
  fi
  if [[ ! -d /opt/pulse ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/rcourtman/Pulse/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop pulse
    msg_ok "Stopped ${APP}"

    msg_info "Updating Pulse"
    temp_file=$(mktemp)
    mkdir -p /opt/pulse
    rm -rf /opt/pulse/*
    curl -fsSL "https://github.com/rcourtman/Pulse/releases/download/v${RELEASE}/pulse-v${RELEASE}.tar.gz" -o "$temp_file"
    tar zxf "$temp_file" --strip-components=1 -C /opt/pulse
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated Pulse to ${RELEASE}"

    msg_info "Setting permissions for /opt/pulse..."
    chown -R pulse:pulse "/opt/pulse"
    find "/opt/pulse" -type d -exec chmod 755 {} \;
    find "/opt/pulse" -type f -exec chmod 644 {} \;
    msg_ok "Set permissions."

    msg_info "Starting ${APP}"
    systemctl start pulse
    msg_ok "Started ${APP}"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}."
  fi
  exit  
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7655${CL}"
