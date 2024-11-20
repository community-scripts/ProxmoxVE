#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
 _       ___           ______                     __
| |     / (_)_______  / ____/_  ______ __________/ /
| | /| / / / ___/ _ \/ / __/ / / / __ `/ ___/ __  / 
| |/ |/ / / /  /  __/ /_/ / /_/ / /_/ / /  / /_/ /  
|__/|__/_/_/   \___/\____/\__,_/\__,_/_/   \__,_/   
                                                    
EOF
}
header_info
echo -e "Loading..."
APP="Wireguard"
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
check_container_storage
check_container_resources
if [[ ! -d /etc/wireguard ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
apt-get update
apt-get -y upgrade
sleep 2
cd /etc/wgdashboard/src
./wgd.sh update
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "WGDashboard should be reachable by going to the following URL.
         ${BL}http://${IP}:10086${CL} \n"
