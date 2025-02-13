#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nxvms.com/download/releases/linux

APP="NxWitness"
var_tags="nvr"
var_cpu="2"
var_ram="2048"
var_disk="8"
var_os="ubuntu"
var_version="24.04"
var_unprivileged="0"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/networkoptix-mediaserver.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  BASE_URL="https://updates.networkoptix.com/default/index.html"
  RELEASE=$(curl -s "$BASE_URL" | grep -oP '(?<=<b>)[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(?=</b>)' | head -n 1)
  DETAIL_PAGE=$(curl -s "$BASE_URL#note_$RELEASE")
  DOWNLOAD_URL=$(echo "$DETAIL_PAGE" | grep -oP "https://updates.networkoptix.com/default/$RELEASE/linux/nxwitness-server-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+-linux_x64\.deb" | head -n 1)
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop networkoptix-root-tool networkoptix-mediaserver
    msg_ok "${APP} Stopped"

    msg_info "Updating ${APP} to ${RELEASE}"
    cd /tmp
    wget -q "$DOWNLOAD_URL" -O "nxwitness-server-$RELEASE-linux_x64.deb"
    export DEBIAN_FRONTEND=noninteractive
    export DEBCONF_NOWARNINGS=yes
    dpkg -i nxwitness-server-$RELEASE-linux_x64.deb >/dev/null 2>&1
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP}"

    msg_info "Starting ${APP}"
    systemctl start networkoptix-root-tool networkoptix-mediaserver
    msg_ok "Started ${APP}"

    msg_info "Cleaning up"
    rm -f /tmp/nxwitness-server-$RELEASE-linux_x64.deb
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7001/${CL}"
