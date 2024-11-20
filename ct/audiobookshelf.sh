#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
                   ___       __                __        __         ______
  ____ ___  ______/ (_)___  / /_  ____  ____  / /_______/ /_  ___  / / __/
 / __ `/ / / / __  / / __ \/ __ \/ __ \/ __ \/ //_/ ___/ __ \/ _ \/ / /_  
/ /_/ / /_/ / /_/ / / /_/ / /_/ / /_/ / /_/ / ,< (__  ) / / /  __/ / __/  
\__,_/\__,_/\__,_/_/\____/_.___/\____/\____/_/|_/____/_/ /_/\___/_/_/     
                                                                          
EOF
}
header_info
echo -e "Loading..."
APP="audiobookshelf"
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
if [[ ! -f /etc/apt/trusted.gpg.d/audiobookshelf-ppa.asc ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
echo "This application receives updates through the APT package manager."
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:13378${CL} \n"
