#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: kristocopani
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____                 ________  ______    __
   /  _/___  _________  /  _/ __ \/ ____/___/ /
   / // __ \/ ___/ __ \ / // /_/ / /   / __  / 
 _/ // / / (__  ) /_/ // // _, _/ /___/ /_/ /  
/___/_/ /_/____/ .___/___/_/ |_|\____/\__,_/   
              /_/                              
 
EOF
}
header_info
echo -e "Loading..."
APP="InspIRCd"
var_disk="2"
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
check_container_storage
check_container_resources

  if [[ ! -f /lib/systemd/system/inspircd.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/inspircd/inspircd/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop inspircd
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${RELEASE}"
    cd /opt
    wget -q https://github.com/inspircd/inspircd/releases/download/v${RELEASE}/inspircd_${RELEASE}.deb12u1_amd64.deb
    apt-get install "./inspircd_${RELEASE}.deb12u1_amd64.deb" -y &>/dev/nul
    echo "${RELEASE}" >"/opt/${APP}_version.txt"
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start inspircd
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf /opt/inspircd_${RELEASE}.deb12u1_amd64.deb
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
         ${BL}Server Name:${IP} Port:6667${CL} \n"