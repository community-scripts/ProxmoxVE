#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/develop/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____             __            __    _                 
   / __ \____  _____/ /____  __   / /   (_)___  __  ___  __
  / /_/ / __ \/ ___/ //_/ / / /  / /   / / __ \/ / / / |/_/
 / _, _/ /_/ / /__/ ,< / /_/ /  / /___/ / / / / /_/ />  <  
/_/ |_|\____/\___/_/|_|\__, /  /_____/_/_/ /_/\__,_/_/|_|  
                      /____/                               
 
EOF
}
header_info
echo -e "Loading..."
APP="Rocky Linux"
var_disk="1"
var_cpu="1"
var_ram="512"
var_os="rockylinux"
var_version="9"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW="-password rockylinux"
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
if [[ ! -d /etc/pacman.d ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating ${APP} LXC"
dnf -y update
dnf -y upgrade
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
