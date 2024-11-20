#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    __  __                         
   / / / /___  ____ ___  ___  _____
  / /_/ / __ \/ __ `__ \/ _ \/ ___/
 / __  / /_/ / / / / / /  __/ /    
/_/ /_/\____/_/ /_/ /_/\___/_/     
                                   
EOF
}
header_info
echo -e "Loading..."
APP="Homer"
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
if [[ ! -d /opt/homer ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Stopping ${APP}"
systemctl stop homer
msg_ok "Stopped ${APP}"

msg_info "Backing up assets directory"
cd ~
mkdir -p assets-backup
cp -R /opt/homer/assets/. assets-backup
msg_ok "Backed up assets directory"

msg_info "Updating ${APP}"
rm -rf /opt/homer/*
cd /opt/homer
wget -q https://github.com/bastienwirtz/homer/releases/latest/download/homer.zip
unzip homer.zip &>/dev/null
msg_ok "Updated ${APP}"

msg_info "Restoring assets directory"
cd ~
cp -Rf assets-backup/. /opt/homer/assets/
msg_ok "Restored assets directory"

msg_info "Cleaning"
rm -rf assets-backup /opt/homer/homer.zip
msg_ok "Cleaned"

msg_info "Starting ${APP}"
systemctl start homer
msg_ok "Started ${APP}"
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8010${CL} \n"
