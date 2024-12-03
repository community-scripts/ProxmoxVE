#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/michelroegl-brunner/ProxmoxVE/refs/heads/dev/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
function header_info {
clear
cat <<"EOF"
    ___                     __            ______                                       __   
   /   |  ____  ____ ______/ /_  ___     / ____/_  ______ __________ _____ ___  ____  / /__ 
  / /| | / __ \/ __ `/ ___/ __ \/ _ \   / / __/ / / / __ `/ ___/ __ `/ __ `__ \/ __ \/ / _ \
 / ___ |/ /_/ / /_/ / /__/ / / /  __/  / /_/ / /_/ / /_/ / /__/ /_/ / / / / / / /_/ / /  __/
/_/  |_/ .___/\__,_/\___/_/ /_/\___/   \____/\__,_/\__,_/\___/\__,_/_/ /_/ /_/\____/_/\___/ 
      /_/                                                                                   
EOF
}
header_info
echo -e "Loading..."
APP="Apache-Guacamole"

var_disk="4"
var_cpu="1"
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

start
build_container
description

msg_ok "Completed Successfully!\n"
