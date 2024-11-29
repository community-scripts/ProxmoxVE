#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/kristocopani/ProxmoxVE/build/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: kristocopani
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   _____                            __                  
  / ___/___  ____ ___  ____ _____  / /_  ____  ________ 
  \__ \/ _ \/ __ `__ \/ __ `/ __ \/ __ \/ __ \/ ___/ _ \
 ___/ /  __/ / / / / / /_/ / /_/ / / / / /_/ / /  /  __/
/____/\___/_/ /_/ /_/\__,_/ .___/_/ /_/\____/_/   \___/ 
                         /_/                            
 
EOF
}
header_info
echo -e "Loading..."
APP="Semaphore"
var_disk="4"
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

  if [[ ! -f /etc/systemd/system/semaphore.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
    RELEASE=$(curl -s https://api.github.com/repos/semaphoreui/semaphore/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop semaphore
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${RELEASE}"
    cd /opt
    wget -q https://github.com/semaphoreui/semaphore/releases/download/v${RELEASE}/semaphore_${RELEASE}_linux_amd64.deb
    dpkg -i semaphore_${RELEASE}_linux_amd64.deb  &>/dev/null
    echo "${RELEASE}" >"/opt/${APP}_version.txt"
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start semaphore
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf /opt/semaphore_${RELEASE}_linux_amd64.deb 
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} server should be reachable by connecting to the following server.
         ${BL}http://${IP}:3000${CL} \n"