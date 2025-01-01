#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://checkmk.com/

APP="checkmk"
var_tags="monitoring"
var_cpu="2"
var_ram="2048"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
base_settings

variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /opt/checkmk_version.txt ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/checkmk/checkmk/tags | grep "name" | awk '{print substr($2, 3, length($2)-4) }' | grep -v "*-rc" | tail -n +2 | head -n 1)
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Updating ${APP} to v${RELEASE}"
    omd stop monitoring &>/dev/null
    omd cp monitoring monitoringbackup &>/dev/null
    wget -q https://download.checkmk.com/checkmk/${RELEASE}/check-mk-raw-${RELEASE}_0.bookworm_amd64.deb -O /opt/checkmk.deb
    apt-get install -y /opt/checkmk.deb &>/dev/null
    omd --force -V ${RELEASE}.cre update --conflict=install monitoring &>/dev/null
    omd start monitoring &>/dev/null
    omd -f rm monitoringbackup  &>/dev/null
    omd cleanup &>/dev/null
    rm -rf /opt/checkmk.deb
    msg_ok "Updated ${APP} to v${RELEASE}"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/monitoring${CL}"
