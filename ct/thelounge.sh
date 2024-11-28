#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/kristocopani/ProxmoxVE/build/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
  ________            __                               
 /_  __/ /_  ___     / /   ____  __  ______  ____ ____ 
  / / / __ \/ _ \   / /   / __ \/ / / / __ \/ __ `/ _ \
 / / / / / /  __/  / /___/ /_/ / /_/ / / / / /_/ /  __/
/_/ /_/ /_/\___/  /_____/\____/\__,_/_/ /_/\__, /\___/ 
                                          /____/        
EOF
}
header_info
echo -e "Loading..."
APP="The Lounge"
var_disk="4"
var_cpu="2"
var_ram="2048"
var_os="ubuntu"
var_version="24.04"
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

  if [[ ! -f /usr/lib/systemd/system/thelounge.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/thelounge/thelounge-deb/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "v${RELEASE}" != "$(sudo -u thelounge thelounge -v)" ]]; then
    msg_info "Stopping ${APP} Services"
    systemctl stop thelounge
    msg_ok "Stopped ${APP} Services"

    msg_info "Updating ${APP} to ${RELEASE}"
    apt-get install --only-upgrade \
      nodejs
    cd /opt
    wget -q https://github.com/thelounge/thelounge-deb/releases/download/v${RELEASE}/thelounge_${RELEASE}_all.deb
    dpkg -i ./thelounge_${RELEASE}_all.deb
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting ${APP} Services"
    systemctl daemon-reload
    systemctl start thelounge
    msg_ok "Started ${APP}"

    msg_info "Cleaning up"
    rm -rf "/opt/thelounge_${RELEASE}_all.deb"
    apt-get -y autoremove
    apt-get -y autoclean
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required.  ${APP} is already at ${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:9000${CL} \n"
