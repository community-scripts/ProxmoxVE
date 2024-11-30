#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: kristocopani
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
  ________               __                               
 /_  __/ /_  ___        / /   ____  __  ______  ____ ____ 
  / / / __ \/ _ \______/ /   / __ \/ / / / __ \/ __ `/ _ \
 / / / / / /  __/_____/ /___/ /_/ / /_/ / / / / /_/ /  __/
/_/ /_/ /_/\___/     /_____/\____/\__,_/_/ /_/\__, /\___/ 
                                             /____/       
EOF
}
header_info
echo -e "Loading..."
APP="The-Lounge"
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
  VERB="yes"
  echo_default
}

function update_script() {
header_info
check_container_storage
check_container_resources
if [[ ! -f /usr/lib/systemd/system/thelounge.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/thelounge/thelounge-deb/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Stopping Service"
  systemctl stop thelounge
  msg_ok "Stopped Service"

  msg_info "Updating ${APP} to v${RELEASE}"
  apt-get install --only-upgrade nodejs &>/dev/null
  cd /opt
  wget -q https://github.com/thelounge/thelounge-deb/releases/download/v${RELEASE}/thelounge_${RELEASE}_all.deb
  dpkg -i ./thelounge_${RELEASE}_all.deb
  msg_ok "Updated ${APP} to v${RELEASE}"

  msg_info "Starting Service"
  systemctl start thelounge
  msg_ok "Started Service"

  msg_info "Cleaning up"
  rm -rf "/opt/thelounge_${RELEASE}_all.deb"
  msg_ok "Cleaned"
  msg_ok "Updated Successfully"
else
  msg_ok "No update required.  ${APP} is already at v${RELEASE}."
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:9000${CL} \n"
