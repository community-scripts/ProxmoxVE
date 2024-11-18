#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
  ________                        _______     
 /_  __/ /_  ________  ____ _____/ / __(_)___ 
  / / / __ \/ ___/ _ \/ __ `/ __  / /_/ / __ \
 / / / / / / /  /  __/ /_/ / /_/ / __/ / / / /
/_/ /_/ /_/_/   \___/\__,_/\__,_/_/ /_/_/ /_/ 
                                              
EOF
}
header_info
echo -e "Loading..."
APP="Threadfin"
var_disk="4"
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
if [[ ! -d /opt/threadfin ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating $APP"
systemctl stop threadfin.service
wget -q -O /opt/threadfin/threadfin 'https://github.com/Threadfin/Threadfin/releases/latest/download/Threadfin_linux_amd64'
chmod +x /opt/threadfin/threadfin
systemctl start threadfin.service
msg_ok "Updated $APP"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:34400/web${CL} \n"
