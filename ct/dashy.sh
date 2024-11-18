#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____             __         
   / __ \____ ______/ /_  __  __
  / / / / __  / ___/ __ \/ / / /
 / /_/ / /_/ (__  ) / / / /_/ / 
/_____/\__,_/____/_/ /_/\__, /  
                       /____/   
EOF
}
header_info
echo -e "Loading..."
APP="Dashy"
var_disk="6"
var_cpu="2"
var_ram="2048"
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
if [[ ! -d /opt/dashy/public/ ]]; then msg_error "No ${APP} Installation Found!"; exit; fi

RELEASE=$(curl -sL https://api.github.com/repos/Lissy93/dashy/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
  msg_info "Stopping ${APP}"
  systemctl stop dashy
  msg_ok "Stopped ${APP}"

  msg_info "Backing up conf.yml"
  cd ~
  if [[ -f /opt/dashy/public/conf.yml ]]; then
    cp -R /opt/dashy/public/conf.yml conf.yml
  else
    cp -R /opt/dashy/user-data/conf.yml conf.yml
  fi
  msg_ok "Backed up conf.yml"

  msg_info "Updating ${APP} to ${RELEASE}"
  rm -rf /opt/dashy
  mkdir -p /opt/dashy
  wget -qO- https://github.com/Lissy93/dashy/archive/refs/tags/${RELEASE}.tar.gz | tar -xz -C /opt/dashy --strip-components=1
  cd /opt/dashy
  npm install
  npm run build
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP} to ${RELEASE}"

  msg_info "Restoring conf.yml"
  cd ~
  cp -R conf.yml /opt/dashy/user-data
  msg_ok "Restored conf.yml"

  msg_info "Cleaning"
  rm -rf conf.yml /opt/dashy/public/conf.yml
  msg_ok "Cleaned"

  msg_info "Starting Dashy"
  systemctl start dashy
  msg_ok "Started Dashy"
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
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:4000${CL} \n"
