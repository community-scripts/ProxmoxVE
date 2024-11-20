#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
       __           __        __  __ 
      / /___ ______/ /_____  / /_/ /_
 __  / / __ `/ ___/ //_/ _ \/ __/ __/
/ /_/ / /_/ / /__/ ,< /  __/ /_/ /_  
\____/\__,_/\___/_/|_|\___/\__/\__/  
                                     
EOF
}
header_info
echo -e "Loading..."
APP="Jackett"
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
if [[ ! -f /etc/systemd/system/jackett.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep "title>Release" | cut -d " " -f 4)
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Updating ${APP}"
  wget -q https://github.com/Jackett/Jackett/releases/download/$RELEASE/Jackett.Binaries.LinuxAMDx64.tar.gz
  systemctl stop jackett
  rm -rf /opt/Jackett
  tar -xzf Jackett.Binaries.LinuxAMDx64.tar.gz -C /opt
  rm -rf Jackett.Binaries.LinuxAMDx64.tar.gz
  systemctl start jackett
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP} to ${RELEASE}"
else
  msg_ok "No update required. ${APP} is already at ${RELEASE}"
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:9117${CL}\n"
