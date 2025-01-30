#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.tp-link.com/us/support/download/omada-software-controller/

# App Default Values
APP="Omada"
var_tags="tp-link;controller"
var_cpu="2"
var_ram="2048"
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
  if [[ ! -d /opt/tplink ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  latest_url=$(curl -s "https://support.omadanetworks.com/en/product/omada-software-controller/?resourceType=download" | grep -o 'https://static\.tp-link\.com/upload/software/[^"]*linux_x64[^"]*\.deb' | head -n 1)
  latest_version=$(basename "$latest_url")
  if [ -z "${latest_version}" ]; then
    msg_error "It seems that the server (tp-link.com) might be down. Please try again at a later time."
    exit
  fi
  echo -e "Updating Omada Controller"
  wget -qL ${latest_url}
  dpkg -i ${latest_version}
  rm -rf ${latest_version}
  echo -e "Updated Omada Controller"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8043${CL}"
