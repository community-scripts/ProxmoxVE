#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# Co-Author: remz1337
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ________               _____       __                    
   / ____/ /___ _________ / ___/____  / /   _____  __________
  / /_  / / __ `/ ___/ _ \\__ \/ __ \/ / | / / _ \/ ___/ ___/
 / __/ / / /_/ / /  /  __/__/ / /_/ / /| |/ /  __/ /  / /    
/_/   /_/\__,_/_/   \___/____/\____/_/ |___/\___/_/  /_/     

EOF
}
header_info
echo -e "Loading..."
APP="FlareSolverr"
var_disk="4"
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
  if [[ ! -f /etc/systemd/system/flaresolverr.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  RELEASE=$(wget -q https://github.com/FlareSolverr/FlareSolverr/releases/latest -O - | grep "title>Release" | cut -d " " -f 4)
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Updating $APP LXC"
    systemctl stop flaresolverr
    wget -q https://github.com/FlareSolverr/FlareSolverr/releases/download/$RELEASE/flaresolverr_linux_x64.tar.gz
    tar -xzf flaresolverr_linux_x64.tar.gz -C /opt
    rm flaresolverr_linux_x64.tar.gz
    systemctl start flaresolverr
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP LXC"
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
         ${BL}http://${IP}:8191${CL} \n"
