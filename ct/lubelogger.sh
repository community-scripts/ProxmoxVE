#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/kristocopani/ProxmoxVE/build/misc/build.func)
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
if [[ ! -d /var ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating $APP LXC"
apt-get update &>/dev/null
apt-get -y upgrade &>/dev/null
msg_ok "Updated $APP LXC"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:5000${CL} \n"
