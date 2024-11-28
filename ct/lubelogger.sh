#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: kristocopani
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    __          __         __                               
   / /   __  __/ /_  ___  / /   ____  ____ _____ ____  _____
  / /   / / / / __ \/ _ \/ /   / __ \/ __ `/ __ `/ _ \/ ___/
 / /___/ /_/ / /_/ /  __/ /___/ /_/ / /_/ / /_/ /  __/ /    
/_____/\__,_/_.___/\___/_____/\____/\__, /\__, /\___/_/     
                                   /____//____/             

EOF
}
header_info
echo -e "Loading..."
APP="LubeLogger"
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

  if [[ ! -f /etc/systemd/system/lubelogger.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -s https://api.github.com/repos/hargata/lubelog/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  RELEASE_TRIMMED=$(echo "${RELEASE}" | tr -d ".")
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop lubelogger
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${RELEASE}"
    cd /opt
    wget -q https://github.com/hargata/lubelog/releases/download/v${RELEASE}/LubeLogger_v${RELEASE_TRIMMED}_linux_x64.zip
    cp /opt/lubelogger/appsettings.json /opt/appsettings.json
    rm -rf /opt/lubelogger
    unzip -qq LubeLogger_v${RELEASE_TRIMMED}_linux_x64.zip -d lubelogger
    chmod 700 /opt/lubelogger/CarCareTracker
    mv -f /opt/appsettings.json /opt/lubelogger/appsettings.json
    echo "${RELEASE}" >"/opt/${APP}_version.txt"
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start lubelogger
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf /opt/LubeLogger_v${RELEASE_TRIMMED}_linux_x64.zip
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
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:5000${CL} \n"
