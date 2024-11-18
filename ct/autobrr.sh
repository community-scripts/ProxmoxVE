#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ___         __        __             
   /   | __  __/ /_____  / /_  __________
  / /| |/ / / / __/ __ \/ __ \/ ___/ ___/
 / ___ / /_/ / /_/ /_/ / /_/ / /  / /    
/_/  |_\__,_/\__/\____/_.___/_/  /_/     
                                         
EOF
}
header_info
echo -e "Loading..."
APP="Autobrr"
var_disk="8"
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
if [[ ! -f /root/.config/autobrr/config.toml ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Stopping ${APP} LXC"
systemctl stop autobrr.service
msg_ok "Stopped ${APP} LXC"

msg_info "Updating ${APP} LXC"
rm -rf /usr/local/bin/*
wget -q $(curl -s https://api.github.com/repos/autobrr/autobrr/releases/latest | grep download | grep linux_x86_64 | cut -d\" -f4)
tar -C /usr/local/bin -xzf autobrr*.tar.gz
rm -rf autobrr*.tar.gz
msg_ok "Updated ${APP} LXC"

msg_info "Starting ${APP} LXC"
systemctl start autobrr.service
msg_ok "Started ${APP} LXC"
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:7474${CL} \n"
