#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: davalanche
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mylar3/mylar3

function header_info {
clear
cat <<"EOF"
    __  ___      __          _____
   /  |/  /_  __/ /___ _____|__  /
  / /|_/ / / / / / __ `/ ___//_ <
 / /  / / /_/ / / /_/ / /  ___/ /
/_/  /_/\__, /_/\__,_/_/  /____/
       /____/
EOF
}
header_info
echo -e "Loading..."
APP="Mylar3"
var_disk="4"
var_cpu="1"
var_ram="512"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
header_info
if [[ ! -d /opt/mylar3 ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/mylar3/mylar3/releases/latest | jq -r '.tag_name')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Updating ${APP} to ${RELEASE}"
  rm -rf /opt/mylar3/* /opt/mylar3/.*
  wget -qO- https://github.com/mylar3/mylar3/archive/refs/tags/${RELEASE}.tar.gz | tar -xz --strip-components=1 -C /opt/mylar3
  systemctl restart mylar3
  echo "${RELEASE}" > /opt/${APP}_version.txt
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
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8090${CL} \n"
