#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://vikunja.io/

function header_info {
clear
cat <<"EOF"
 _    ___ __                 _      
| |  / (_) /____  ______    (_)___ _
| | / / / //_/ / / / __ \  / / __ `/
| |/ / / ,< / /_/ / / / / / / /_/ / 
|___/_/_/|_|\__,_/_/ /_/_/ /\__,_/  
                      /___/         

EOF
}
header_info
echo -e "Loading..."
APP="Vikunja"
var_disk="4"
var_cpu="1"
var_ram="1024"
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
check_container_storage
check_container_resources
if [[ ! -d /opt/vikunja ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://dl.vikunja.io/vikunja/ | grep -oP 'href="/vikunja/\K[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n 1)
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Stopping ${APP}"
  systemctl stop vikunja
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP} to ${RELEASE}"
  cd /opt
  rm -rf /opt/*
  wget -q "https://dl.vikunja.io/vikunja/$RELEASE/vikunja-$RELEASE-amd64.deb"
  DEBIAN_FRONTEND=noninteractive dpkg -i vikunja-$RELEASE-amd64.deb &>/dev/null
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP}"

  msg_info "Starting ${APP}"
  systemctl start vikunja
  msg_ok "Started ${APP}"

  msg_info "Cleaning Up"
  rm -rf /opt/vikunja-$RELEASE-amd64.deb
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
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:3456${CL} \n"
