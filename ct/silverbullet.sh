#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: Dominik Siebel (dsiebel)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://silverbullet.md

# App default values
APP="Silverbullet"
var_tags="notes"
var_cpu="1"
var_disk="2"
var_ram="512"
var_os="debian"
var_version="12"

# App Output & Base Settings
header_info "${APP}"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/silverbullet ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  RELEASE=$(curl -s https://api.github.com/repos/silverbulletmd/silverbullet/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ ! -f "/opt/${APP}_version.txt" || "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop silverbullet
    msg_ok "Stopped ${APP}"

    msg_info "Updating ${APP} to v${RELEASE}"
    wget -q https://github.com/silverbulletmd/silverbullet/releases/download/${RELEASE}/silverbullet-server-linux-x86_64.zip
    unzip -q silverbullet-server-linux-x86_64.zip
    mv silverbullet /opt/silverbullet/bin/
    chmod +x /opt/silverbullet/bin/silverbullet
    echo "${RELEASE}" >/opt/silverbullet/${APP}_version.txt
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting ${APP}"
    systemctl start silverbullet
    msg_ok "Started ${APP}"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
