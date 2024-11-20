#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    ____  __  ______  __________  ____  ____  _________ __  ___
   / __ \/ / / / __ \/_  __/ __ \/ __ \/ __ \/  _/ ___//  |/  /
  / /_/ / /_/ / / / / / / / / / / /_/ / /_/ // / \__ \/ /|_/ / 
 / ____/ __  / /_/ / / / / /_/ / ____/ _, _// / ___/ / /  / /  
/_/   /_/ /_/\____/ /_/  \____/_/   /_/ |_/___//____/_/  /_/   

EOF
}
header_info
echo -e "Loading..."
APP="PhotoPrism"
var_disk="8"
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
  if [[ ! -d /opt/photoprism ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  echo -e "\n ⚠️  Ensure you set 2vCPU & 3072MiB RAM MIMIMUM!!! \n"
  msg_info "Stopping PhotoPrism"
  sudo systemctl stop photoprism
  msg_ok "Stopped PhotoPrism"

  msg_info "Updating PhotoPrism"
  apt-get install -y libvips42 &>/dev/null
  wget -q -cO - https://dl.photoprism.app/pkg/linux/amd64.tar.gz | tar -xzf - -C /opt/photoprism --strip-components=1
  msg_ok "Updated PhotoPrism"

  msg_info "Starting PhotoPrism"
  sudo systemctl start photoprism
  msg_ok "Started PhotoPrism"
  msg_ok "Update Successful"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:2342${CL} \n"
