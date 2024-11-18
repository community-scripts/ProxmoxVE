#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
  ______     _ ___               
 /_  __/____(_) (_)_  ______ ___ 
  / / / ___/ / / / / / / __ `__ \
 / / / /  / / / / /_/ / / / / / /
/_/ /_/  /_/_/_/\__,_/_/ /_/ /_/ 
                                                                      
EOF
}
header_info
echo -e "Loading..."
APP="Trilium"
var_disk="2"
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
if [[ ! -d /opt/trilium ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/TriliumNext/Notes/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    
msg_info "Stopping ${APP}"
systemctl stop trilium.service
sleep 1
msg_ok "Stopped ${APP}"

msg_info "Updating to ${RELEASE}"
wget -q https://github.com/TriliumNext/Notes/releases/download/${RELEASE}/TriliumNextNotes-${RELEASE}-server-linux-x64.tar.xz
tar -xf TriliumNextNotes-${RELEASE}-server-linux-x64.tar.xz
cp -r trilium-linux-x64-server/* /opt/trilium/
msg_ok "Updated to ${RELEASE}"

msg_info "Cleaning up"
rm -rf TriliumNextNotes-${RELEASE}-server-linux-x64.tar.xz trilium-linux-x64-server
msg_ok "Cleaned"

msg_info "Starting ${APP}"
systemctl start trilium.service
sleep 1
msg_ok "Started ${APP}"
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8080${CL} \n"
