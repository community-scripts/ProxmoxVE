#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____                 __          __
   / __ \___  ____ _____/ /__  _____/ /__
  / /_/ / _ \/ __ `/ __  / _ \/ ___/ //_/
 / _, _/  __/ /_/ / /_/ /  __/ /__/ ,<
/_/ |_|\___/\__,_/\__,_/\___/\___/_/|_|

EOF
}
header_info
echo -e "Loading..."
APP="Readeck"
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
if [[ ! -d /opt/readeck ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating ${APP}"
LATEST=$(curl -s https://codeberg.org/readeck/readeck/releases/ | grep -oP '(?<=Version )\d+\.\d+\.\d+' | head -1)
systemctl stop readeck.service
rm -rf /opt/readeck/readeck
cd /opt/readeck
wget -q -O readeck https://codeberg.org/readeck/readeck/releases/download/${LATEST}/readeck-${LATEST}-linux-amd64
chmod a+x readeck
systemctl start readeck.service
msg_ok "Updated ${APP}"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
             ${BL}http://${IP}:8000${CL}\n"
