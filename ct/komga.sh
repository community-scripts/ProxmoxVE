#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2024 madelyn
# Author: madelyn (DysfunctionalProgramming)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
 _  __                           
| |/ /___  _ __ ___   __ _  __ _ 
| ' // _ \| '_ ` _ \ / _` |/ _` |
| . \ (_) | | | | | | (_| | (_| |
|_|\_\___/|_| |_| |_|\__, |\__,_|
                     |___/       
EOF
}
header_info
echo -e "Loading..."
APP="Komga"
var_disk="4"
var_cpu="1"
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
if [[ ! -d /opt/komga ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating ${APP}"
RELEASE=$(curl -s https://api.github.com/repos/gotson/komga/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
if [[ ! -d /opt/komga/komga-${RELEASE}.jar ]]; then
  systemctl stop komga
  msg_info "Downloading ${APP} v$RELEASE"
  wget -q "https://github.com/gotson/komga/releases/download/v$RELEASE/komga-${RELEASE}.jar"
  mkdir -p /opt/komga
  mv -f komga-${RELEASE}.jar /opt/komga/komga-${RELEASE}.jar
  systemctl start komga
fi
msg_ok "Updated ${APP} to v$RELEASE"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:25600 ${CL} \n"
