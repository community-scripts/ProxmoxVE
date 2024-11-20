#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# Co-Author: ulmentflam
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    __ __      __
   / //_/_  __/ /_  ____
  / ,< / / / / __ \/ __ \
 / /| / /_/ / /_/ / /_/ /
/_/ |_\__,_/_.___/\____/
EOF
}
header_info
echo -e "Loading..."
APP="Kubo"
var_disk="4"
var_cpu="2"
var_ram="4096"
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
if [[ ! -f /usr/local/kubo ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(wget -q https://github.com/ipfs/kubo/releases/latest -O - | grep "title>Release" | cut -d " " -f 4)
if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
  msg_info "Updating $APP LXC"
  apt-get update &>/dev/null
  apt-get -y upgrade &>/dev/null
  wget -q "https://github.com/ipfs/kubo/releases/download/${RELEASE}/kubo_${RELEASE}_linux-amd64.tar.gz"
  tar -xzf "kubo_${RELEASE}_linux-amd64.tar.gz" -C /usr/local
  systemctl restart ipfs.service
  echo "${RELEASE}" >/opt/${APP}_version.txt
  rm "kubo_${RELEASE}_linux-amd64.tar.gz"
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
         ${BL}http://${IP}:5001/webui ${CL} \n"
