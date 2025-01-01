#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/matze/wastebin

# App Default Values
APP="Wastebin"
var_tags="file;code"
var_cpu="1"
var_ram="1024"
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
  if [[ ! -d /opt/wastebin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/matze/wastebin/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Wastebin"
    systemctl stop wastebin
    msg_ok "Wastebin Stopped"

    msg_info "Updating Wastebin"
    wget -q https://github.com/matze/wastebin/releases/download/${RELEASE}/wastebin_${RELEASE}_x86_64-unknown-linux-musl.tar.zst
    tar -xf wastebin_${RELEASE}_x86_64-unknown-linux-musl.tar.zst
    cp -f wastebin /opt/wastebin/
    chmod +x /opt/wastebin/wastebin
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated Wastebin"

    msg_info "Starting Wastebin"
    systemctl start wastebin
    msg_ok "Started Wastebin"

    msg_info "Cleaning Up"
    rm -rf wastebin_${RELEASE}_x86_64-unknown-linux-musl.tar.zst
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8088${CL}"