#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ___       __                           __
   /   | ____/ /___ ___  ______ __________/ /
  / /| |/ __  / __  / / / / __  / ___/ __  / 
 / ___ / /_/ / /_/ / /_/ / /_/ / /  / /_/ /  
/_/  |_\__,_/\__, /\__,_/\__,_/_/   \__,_/   
            /____/                           
 
EOF
}
header_info
echo -e "Loading..."
APP="Adguard"
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
if [[ ! -d /opt/AdGuardHome ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_error "Adguard Home should be updated via the user interface."
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:3000${CL} \n"
