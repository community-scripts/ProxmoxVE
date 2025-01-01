#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.bunkerweb.io/

# App Default Values
APP="BunkerWeb"
var_tags="webserver"
var_cpu="2"
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
  if [[ ! -d /etc/bunkerweb ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  RELEASE=$(curl -s https://api.github.com/repos/bunkerity/bunkerweb/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then

  msg_info "Updating ${APP} to ${RELEASE}"
  cat <<EOF >/etc/apt/preferences.d/bunkerweb
Package: bunkerweb
Pin: version ${RELEASE}
Pin-Priority: 1001
EOF
  apt-get update
  apt-get install -y nginx=1.26.2*
  apt-get install -y bunkerweb=${RELEASE}
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP} to ${RELEASE}"

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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/setup${CL}"