#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/juanfont/headscale

# App Default Values
APP="Headscale"
var_tags="tailscale"
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
  if [[ ! -d /etc/headscale ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/juanfont/headscale/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop headscale
    msg_ok "Stopped ${APP}"

    msg_info "Updating $APP to v${RELEASE}"
    wget -q https://github.com/juanfont/headscale/releases/download/v${RELEASE}/headscale_${RELEASE}_linux_amd64.deb
    dpkg -i headscale_${RELEASE}_linux_amd64.deb
    rm headscale_${RELEASE}_linux_amd64.deb
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to ${RELEASE}"

    msg_info "Starting ${APP}"
    systemctl start headscale
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