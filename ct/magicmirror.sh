#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    __  ___            _      __  ____                     
   /  |/  /___ _____ _(_)____/  |/  (_)_____________  _____
  / /|_/ / __  / __  / / ___/ /|_/ / / ___/ ___/ __ \/ ___/
 / /  / / /_/ / /_/ / / /__/ /  / / / /  / /  / /_/ / /    
/_/  /_/\__,_/\__, /_/\___/_/  /_/_/_/  /_/   \____/_/     
             /____/                                     
 
EOF
}
header_info
echo -e "Loading..."
APP="MagicMirror"
var_disk="3"
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
if [[ ! -d /opt/magicmirror ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  if [[ "$(node -v | cut -d 'v' -f 2)" == "18."* ]]; then
    if ! command -v npm >/dev/null 2>&1; then
      echo "Installing NPM..."
      apt-get install -y npm >/dev/null 2>&1
      echo "Installed NPM..."
    fi
  fi
msg_info "Updating ${APP} LXC"
cd /opt/magicmirror
git pull &>/dev/null
npm install --only=prod --omit=dev &>/dev/null
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8080${CL} \n"
