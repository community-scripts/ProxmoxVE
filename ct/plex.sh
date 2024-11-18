#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____  __             __  ___         ___          _____                          
   / __ \/ /__  _  __   /  |/  /__  ____/ (_)___ _   / ___/___  ______   _____  _____
  / /_/ / / _ \| |/_/  / /|_/ / _ \/ __  / / __ `/   \__ \/ _ \/ ___/ | / / _ \/ ___/
 / ____/ /  __/>  <   / /  / /  __/ /_/ / / /_/ /   ___/ /  __/ /   | |/ /  __/ /    
/_/   /_/\___/_/|_|  /_/  /_/\___/\__,_/_/\__,_/   /____/\___/_/    |___/\___/_/     
                                                                                      
EOF
}
header_info
echo -e "Loading..."
APP="Plex"
var_disk="8"
var_cpu="2"
var_ram="2048"
var_os="ubuntu"
var_version="22.04"
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
if [[ ! -f /etc/apt/sources.list.d/plexmediaserver.list ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select \nplexupdate info >> https://github.com/mrworf/plexupdate" 10 59 2 \
  "1" "Update LXC" ON \
  "2" "Install plexupdate" OFF \
  3>&1 1>&2 2>&3)
if [ "$UPD" == "1" ]; then
msg_info "Updating ${APP} LXC"
apt-get update &>/dev/null
apt-get -y upgrade &>/dev/null
msg_ok "Updated ${APP} LXC"
exit
fi
if [ "$UPD" == "2" ]; then
set +e
bash -c "$(wget -qO - https://raw.githubusercontent.com/mrworf/plexupdate/master/extras/installer.sh)"
exit
fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
             ${BL}http://${IP}:32400/web${CL}\n"
