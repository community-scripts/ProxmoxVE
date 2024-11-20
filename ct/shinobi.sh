#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   _____ __    _             __    _ 
  / ___// /_  (_)___  ____  / /_  (_)
  \__ \/ __ \/ / __ \/ __ \/ __ \/ / 
 ___/ / / / / / / / / /_/ / /_/ / /  
/____/_/ /_/_/_/ /_/\____/_.___/_/   
                                     
EOF
}
header_info
echo -e "Loading..."
APP="Shinobi"
var_disk="8"
var_cpu="2"
var_ram="2048"
var_os="ubuntu"
var_version="22.04"
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
if [[ ! -d /opt/Shinobi ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating Shinobi LXC"
cd /opt/Shinobi
sh UPDATE.sh
pm2 flush
pm2 restart camera
pm2 restart cron
msg_ok "Updated Shinobi LXC"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:8080/super${CL} \n"
