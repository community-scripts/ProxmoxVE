#!/usr/bin/env bash

source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____                                          ____             __                  _____
   / __ \_________  _  ______ ___  ____  _  __   / __ )____ ______/ /____  ______     / ___/___  ______   _____  _____
  / /_/ / ___/ __ \| |/_/ __ `__ \/ __ \| |/_/  / __  / __ `/ ___/ //_/ / / / __ \    \__ \/ _ \/ ___/ | / / _ \/ ___/
 / ____/ /  / /_/ />  </ / / / / / /_/ />  <   / /_/ / /_/ / /__/ ,< / /_/ / /_/ /   ___/ /  __/ /   | |/ /  __/ /
/_/   /_/   \____/_/|_/_/ /_/ /_/\____/_/|_|  /_____/\__,_/\___/_/|_|\__,_/ .___/   /____/\___/_/    |___/\___/_/
                                                                         /_/
EOF
}
header_info
echo -e "Loading..."
APP="PBS"
var_disk="10"
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
if [[ ! -d /var ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating $APP LXC"
apt-get update &>/dev/null
apt-get -y upgrade &>/dev/null
msg_ok "Updated $APP LXC"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8007${CL} \n"
