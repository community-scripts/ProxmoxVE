#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    __  ___         __
   /  |/  /__  ____/ /_  ___________ _
  / /|_/ / _ \/ __  / / / / ___/ __ `/
 / /  / /  __/ /_/ / /_/ (__  ) /_/ / 
/_/  /_/\___/\__,_/\__,_/____/\__,_/

EOF
}
header_info
echo -e "Loading..."
APP="Medusa"
var_disk="6"
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
if [[ ! -d /opt/medusa ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating ${APP}"
systemctl stop medusa.service
/opt/medusa
git pull
systemctl start medusa.service
msg_ok "Successfully Updated ${APP}"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8081${CL} \n"
