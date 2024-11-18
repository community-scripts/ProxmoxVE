#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   ________                           __        ____ _    ______     _____
  / ____/ /_  ____ _____  ____  ___  / /____   / __ \ |  / / __ \   / ___/___  ______   _____  _____
 / /   / __ \/ __ `/ __ \/ __ \/ _ \/ / ___/  / / / / | / / /_/ /   \__ \/ _ \/ ___/ | / / _ \/ ___/
/ /___/ / / / /_/ / / / / / / /  __/ (__  )  / /_/ /| |/ / _, _/   ___/ /  __/ /   | |/ /  __/ /
\____/_/ /_/\__,_/_/ /_/_/ /_/\___/_/____/  /_____/ |___/_/ |_|   /____/\___/_/    |___/\___/_/

EOF
}
header_info
echo -e "Loading..."
APP="Channels"
var_disk="8"
var_cpu="2"
var_ram="1024"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="0"
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
if [[ ! -d /opt/channels-dvr ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_error "There is currently no update path available."
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:8089 ${CL} \n"
