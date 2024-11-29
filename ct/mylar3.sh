#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: davalanche
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mylar3/mylar3

source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
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
msg_error "${APP} should be updated via the user interface."
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8090${CL} \n"
