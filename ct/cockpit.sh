#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck
# Co-Author: havardthom
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"     
   ______           __         _ __
  / ____/___  _____/ /______  (_) /_
 / /   / __ \/ ___/ //_/ __ \/ / __/
/ /___/ /_/ / /__/ ,< / /_/ / / /_
\____/\____/\___/_/|_/ .___/_/\__/
                    /_/
EOF
}
header_info
echo -e "Loading..."
APP="Cockpit"
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
if [[ ! -d /etc/cockpit ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 4 \
  "1" "Update LXC" ON \
  "2" "Install cockpit-file-sharing" OFF \
  "3" "Install cockpit-identities" OFF \
  "4" "Install cockpit-navigator" OFF \
  3>&1 1>&2 2>&3)

header_info
if [ "$UPD" == "1" ]; then
  msg_info "Updating ${APP} LXC"
  apt-get update &>/dev/null
  apt-get -y upgrade &>/dev/null
  msg_ok "Updated ${APP} LXC"
  exit
fi
if [ "$UPD" == "2" ]; then
  msg_info "Installing dependencies (patience)"
  apt-get install -y attr &>/dev/null
  apt-get install -y nfs-kernel-server &>/dev/null
  apt-get install -y samba &>/dev/null
  apt-get install -y samba-common-bin &>/dev/null
  apt-get install -y winbind &>/dev/null
  apt-get install -y gawk &>/dev/null
  msg_ok "Installed dependencies"
  msg_info "Installing Cockpit file sharing"
  LATEST=$(curl -s https://api.github.com/repos/45Drives/cockpit-file-sharing/releases/latest  | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  wget -q https://github.com/45Drives/cockpit-file-sharing/releases/download/v${LATEST}/cockpit-file-sharing_${LATEST}-1focal_all.deb
  dpkg -i cockpit-file-sharing_${LATEST}-1focal_all.deb &>/dev/null
  rm cockpit-file-sharing_${LATEST}-1focal_all.deb
  msg_ok "Installed Cockpit file sharing"
  exit
fi
if [ "$UPD" == "3" ]; then
  msg_info "Installing dependencies (patience)"
  apt-get install -y psmisc &>/dev/null
  apt-get install -y samba &>/dev/null
  apt-get install -y samba-common-bin &>/dev/null
  msg_ok "Installed dependencies"
  msg_info "Installing Cockpit identities"
  LATEST=$(curl -s https://api.github.com/repos/45Drives/cockpit-identities/releases/latest  | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  wget -q https://github.com/45Drives/cockpit-identities/releases/download/v${LATEST}/cockpit-identities_${LATEST}-1focal_all.deb
  dpkg -i cockpit-identities_${LATEST}-1focal_all.deb &>/dev/null
  rm cockpit-identities_${LATEST}-1focal_all.deb
  msg_ok "Installed Cockpit identities"
  exit
fi
if [ "$UPD" == "4" ]; then
  msg_info "Installing dependencies"
  apt-get install -y rsync &>/dev/null
  apt-get install -y zip &>/dev/null
  msg_ok "Installed dependencies"
  msg_info "Installing Cockpit navigator"
  LATEST=$(curl -s https://api.github.com/repos/45Drives/cockpit-navigator/releases/latest  | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  wget -q https://github.com/45Drives/cockpit-navigator/releases/download/v${LATEST}/cockpit-navigator_${LATEST}-1focal_all.deb
  dpkg -i cockpit-navigator_${LATEST}-1focal_all.deb &>/dev/null
  rm cockpit-navigator_${LATEST}-1focal_all.deb
  msg_ok "Installed Cockpit navigator"
  exit
fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:9090${CL} \n"
