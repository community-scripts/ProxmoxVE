#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE
# Source: https://nextpvr.com/

function header_info {
clear
cat <<"EOF"
    _   __          __  ____ _    ______ 
   / | / /__  _  __/ /_/ __ \ |  / / __ \
  /  |/ / _ \| |/_/ __/ /_/ / | / / /_/ /
 / /|  /  __/>  </ /_/ ____/| |/ / _, _/ 
/_/ |_/\___/_/|_|\__/_/     |___/_/ |_|  
                                         
EOF
}
header_info
echo -e "Loading..."
APP="NextPVR"
var_disk="5"
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
if [[ ! -d /opt/nextpvr ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Stopping ${APP}"
systemctl stop nextpvr-server
msg_ok "Stopped ${APP}"

msg_info "Updating LXC packages"
apt-get update &>/dev/null
apt-get -y upgrade &>/dev/null
msg_ok "Updated LXC packages"

msg_info "Updating ${APP}"
cd /opt
wget -q https://nextpvr.com/nextpvr-helper.deb
dpkg -i nextpvr-helper.deb &>/dev/null
msg_ok "Updated ${APP}"

msg_info "Starting ${APP}"
systemctl start nextpvr-server
msg_ok "Started ${APP}"

msg_info "Cleaning Up"
rm -rf /opt/nextpvr-helper.deb
msg_ok "Cleaned"
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:8866${CL} \n"
