#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: community-scripts ORG
# CO-Author: EnterYourUsernameHere
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ProjectURL or https://docs.ProjectURL.com 

function header_info { 
clear 
# Generating Ascii Slant here: https://www.patorjk.com/software/taag/#p=display&f=Slant&t=Template
cat <<"EOF"
  ______                     __      __     
 /_  __/__  ____ ___  ____  / /___ _/ /____ 
  / / / _ \/ __ `__ \/ __ \/ / __ `/ __/ _ \
 / / /  __/ / / / / / /_/ / / /_/ / /_/  __/
/_/  \___/_/ /_/ /_/ .___/_/\__,_/\__/\___/ 
                  /_/                       
EOF
}
header_info
echo -e "Loading..." 
APP="ProjectName" # Name of Github Project or something else, like "Bookstack", "Docker", "Wikipedia"
var_disk="4" # Hard disk space in GB
var_cpu="1" # Number of used CPU cores
var_ram="1024" # Number of used RAM in MB (1024 - 1 GB)
var_os="debian" # Default OS using Script (e.g. Debian, Ubuntu)
var_version="12" # Default OS Version (e.g. 12 for Bookworm, 24.04 for Noble Numbat)
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1" 
  # CT_TYPE 1 => Unprivileged
  # CT_TYPE 0 => Privileged
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
if [[ ! -d /opt/project_folder ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
if (( $(df /boot | awk 'NR==2{gsub("%","",$5); print $5}') > 80 )); then
  read -r -p "Warning: Storage is dangerously low, continue anyway? <y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] || exit
fi
RELEASE=$(curl -s https://api.github.com/repos/project_user/project_folder/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then

# 1st: 
#Stopping Service/s. If more then 1 Service "Stopping ${APP} Services" & "Stopped ${APP} Services"
  msg_info "Stopping ${APP} Service"
  systemctl stop project_servicename
  msg_ok "Stopped ${APP} Service"

  msg_info "Updating ${APP} to ${RELEASE}"
  # Here enter update Script
  # .
  # .
  # .
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP}"

#Starting Service/s. If more then 1 Service "Starting ${APP} Services" & "Started ${APP} Services"
  msg_info "Starting ${APP} Service"
  systemctl start project_servicename
  msg_ok "Started ${APP} Service"

  msg_info "Cleaning Up"
# Clean up for example install Files from RELEASE or something else  
  rm -R /opt/v${RELEASE}.zip
  msg_ok "Cleaned"
  msg_ok "Updated Successfully"
else
  msg_ok "No update required. ${APP} is already at ${RELEASE}"
fi
exit
}

start # Static, do not make any changes!
build_container # Static, do not make any changes!
description # Static, do not make any changes!

msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:12345${CL} \n"