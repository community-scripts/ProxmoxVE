#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Authors: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    ______     _             __
   / ____/____(_)___ _____ _/ /____
  / /_  / ___/ / __ `/ __ `/ __/ _ \
 / __/ / /  / / /_/ / /_/ / /_/  __/
/_/   /_/  /_/\__, /\__,_/\__/\___/
             /____/

EOF
}
header_info
echo -e "Loading..."
APP="Frigate"
var_disk="20"
var_cpu="4"
var_ram="4096"
var_os="debian"
var_version="11"
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
  if [[ ! -f /etc/systemd/system/frigate.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  msg_error "To update Frigate, create a new container and transfer your configuration."
  exit  
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:5000${CL} \n"
echo -e "go2rtc should be reachable by going to the following URL.
         ${BL}http://${IP}:1984${CL} \n"
