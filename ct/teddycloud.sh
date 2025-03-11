#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Dominik Siebel (dsiebel)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/toniebox-reverse-engineering/teddycloud

APP="TeddyCloud"
var_tags="media"
var_cpu="2"
var_disk="8"
var_ram="1024"
var_os="debian"
var_version="12"

header_info "${APP}"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/teddycloud ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  RELEASE="$(curl -s https://api.github.com/repos/toniebox-reverse-engineering/teddycloud/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')"
  VERSION="${RELEASE#tc_v}"
  if [[ ! -f "/opt/${APP}_version.txt" || "${VERSION}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop teddycloud
    msg_ok "Stopped ${APP}"

    msg_info "Updating ${APP} to v${VERSION}"
    cd /opt
    mv /opt/teddycloud /opt/teddycloud_bak
    wget -q "https://github.com/toniebox-reverse-engineering/teddycloud/releases/download/${RELEASE}/teddycloud.amd64.release_v${VERSION}.zip"
    unzip -q -d /opt/teddycloud teddycloud.amd64.release_v${VERSION}.zip
    cp -R /opt/teddycloud_bak/certs /opt/teddycloud_bak/config /opt/teddycloud_bak/data /opt/teddycloud
    echo "${VERSION}" >"/opt/${APP}_version.txt"
    msg_ok "Updated ${APP} to v${VERSION}"

    msg_info "Starting ${APP}"
    systemctl start teddycloud
    msg_ok "Started ${APP}"

    msg_info "Cleaning up"
    rm -rf /opt/teddycloud.amd64.release_v${VERSION}.zip
    rm -rf /opt/teddycloud_bak
    msg_ok "Cleaned"
  else
    msg_ok "No update required. ${APP} is already at v${VERSION}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
