#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    _   __            _     __                        
   / | / /___ __   __(_)___/ /________  ____ ___  ___ 
  /  |/ / __  / | / / / __  / ___/ __ \/ __  __ \/ _ \
 / /|  / /_/ /| |/ / / /_/ / /  / /_/ / / / / / /  __/
/_/ |_/\__,_/ |___/_/\__,_/_/   \____/_/ /_/ /_/\___/ 
 
EOF
}
header_info
echo -e "Loading..."
APP="Navidrome"
var_disk="4"
var_cpu="2"
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
if [[ ! -d /opt/navidrome ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/navidrome/navidrome/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
msg_info "Stopping ${APP}"
systemctl stop navidrome.service
msg_ok "Stopped Navidrome"

msg_info "Updating to v${RELEASE}"
wget https://github.com/navidrome/navidrome/releases/download/v${RELEASE}/navidrome_${RELEASE}_linux_amd64.tar.gz -O Navidrome.tar.gz &>/dev/null
tar -xvzf Navidrome.tar.gz -C /opt/navidrome/ &>/dev/null
msg_ok "Updated ${APP}"
rm Navidrome.tar.gz

msg_info "${GN} Starting ${APP}"
systemctl start navidrome.service
msg_ok "Started ${APP}"
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:4533${CL} \n"
