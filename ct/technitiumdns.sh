#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
  ______          __          _ __  _                    ____  _   _______
 /_  __/__  _____/ /_  ____  (_) /_(_)_  ______ ___     / __ \/ | / / ___/
  / / / _ \/ ___/ __ \/ __ \/ / __/ / / / / __  __ \   / / / /  |/ /\__ \ 
 / / /  __/ /__/ / / / / / / / /_/ / /_/ / / / / / /  / /_/ / /|  /___/ / 
/_/  \___/\___/_/ /_/_/ /_/_/\__/_/\__,_/_/ /_/ /_/  /_____/_/ |_//____/  
 
EOF
}
header_info
echo -e "Loading..."
APP="Technitium DNS"
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
if [[ ! -d /etc/dns ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating ${APP}"

if ! dpkg -s aspnetcore-runtime-8.0 > /dev/null 2>&1; then
    wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb
    dpkg -i packages-microsoft-prod.deb &>/dev/null
    apt-get update &>/dev/null
    apt-get install -y aspnetcore-runtime-8.0 &>/dev/null
    rm packages-microsoft-prod.deb
fi
bash <(curl -fsSL https://download.technitium.com/dns/install.sh) &>/dev/null
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:5380${CL} \n"
