#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    __  ___   ______      __       
   /  |/  /__/_  __/_  __/ /_  ___ 
  / /|_/ / _ \/ / / / / / __ \/ _ \
 / /  / /  __/ / / /_/ / /_/ /  __/
/_/  /_/\___/_/  \__,_/_.___/\___/ 
                                                                
EOF
}
header_info
echo -e "Loading..."
APP="MeTube"
var_disk="10"
var_cpu="1"
var_ram="1024"
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
if [[ ! -d /opt/metube ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Stopping ${APP} Service"
systemctl stop metube
msg_ok "Stopped ${APP} Service"

msg_info "Updating ${APP} to latest Git"
cd /opt
if [ -d metube_bak ]; then
  rm -rf metube_bak
fi
mv metube metube_bak
git clone https://github.com/alexta69/metube /opt/metube  >/dev/null 2>&1
cd /opt/metube/ui
npm install >/dev/null 2>&1
node_modules/.bin/ng build >/dev/null 2>&1
cd /opt/metube
cp /opt/metube_bak/.env /opt/metube/
pip3 install pipenv >/dev/null 2>&1
pipenv install >/dev/null 2>&1

if [ -d "/opt/metube_bak" ]; then
rm -rf /opt/metube_bak
fi
msg_ok "Updated ${APP} to latest Git"

msg_info "Starting ${APP} Service"
systemctl start metube
sleep 1
msg_ok "Started ${APP} Service"
msg_ok "Updated Successfully!\n"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:8081${CL} \n"