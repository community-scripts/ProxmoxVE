#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: caroipdev
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    __  ___      _       __        _                     
   /  |/  /___ _(_)___  / /_____ _(_)___  ___  __________
  / /|_/ / __ `/ / __ \/ __/ __ `/ / __ \/ _ \/ ___/ ___/
 / /  / / /_/ / / / / / /_/ /_/ / / / / /  __/ /  / /    
/_/  /_/\__,_/_/_/ /_/\__/\__,_/_/_/ /_/\___/_/  /_/     
                                                         
EOF
}
header_info
echo -e "Loading..."
APP="Maintainerr"
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
if [[ ! -d /opt/maintainerr ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating ${APP}"
systemctl stop maintainerr.service
cd /opt/maintainerr
git pull &>/dev/null
yarn install &>/dev/null
systemctl start maintainerr.service
msg_ok "Successfully Updated ${APP}"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:6246${CL} \n"