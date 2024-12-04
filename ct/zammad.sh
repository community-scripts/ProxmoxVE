#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
 _____                                       __
/__  /  ____ _____ ___  ____ ___  ____ _____/ /
  / /  / __ `/ __ `__ \/ __ `__ \/ __ `/ __  / 
 / /__/ /_/ / / / / / / / / / / / /_/ / /_/ /  
/____/\__,_/_/ /_/ /_/_/ /_/ /_/\__,_/\__,_/   
EOF
}
header_info
echo -e "Loading..."
APP="Zammad"
var_disk="8"
var_cpu="2"
var_ram="4096"
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
if [[ ! -d /opt/zamad ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Stopping Service"
systemctl stop zammad &>/dev/null
msg_info "Updating ${APP}" 
apt-get update &>/dev/null
apt-mark hold zammad &>/dev/null
apt-get -y upgrade &>/dev/null
apt-mark unhold zammad &>/dev/null
apt-get -y upgrade &>/dev/null
msg_info "Starting Service"
systemctl start zammad &>/dev/null
msg_ok "Updated ${APP} LXC"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
