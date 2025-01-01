#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://technitium.com/dns/

# App Default Values
APP="Technitium DNS"
var_tags="dns"
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
  if [[ ! -d /etc/dns ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP}"

  if ! dpkg -s aspnetcore-runtime-8.0 >/dev/null 2>&1; then
    wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb
    dpkg -i packages-microsoft-prod.deb &>/dev/null
    apt-get update &>/dev/null
    apt-get install -y aspnetcore-runtime-8.0 &>/dev/null
    rm packages-microsoft-prod.deb
  fi
  bash <(curl -fsSL https://download.technitium.com/dns/install.sh) &>/dev/null
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5380${CL}"