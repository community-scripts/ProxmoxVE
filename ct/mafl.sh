#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    __  ___      ______
   /  |/  /___ _/ __/ /
  / /|_/ / __ `/ /_/ /
 / /  / / /_/ / __/ /
/_/  /_/\__,_/_/ /_/

EOF
}
header_info
echo -e "Loading..."
APP="Mafl"
var_disk="6"
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
  if [[ ! -d /opt/mafl ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  RELEASE=$(curl -s https://api.github.com/repos/hywax/mafl/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  msg_info "Updating Mafl to v${RELEASE} (Patience)"
  systemctl stop mafl
  wget -q https://github.com/hywax/mafl/archive/refs/tags/v${RELEASE}.tar.gz
  tar -xzf v${RELEASE}.tar.gz
  cp -r mafl-${RELEASE}/* /opt/mafl/
  rm -rf mafl-${RELEASE}
  cd /opt/mafl
  yarn install
  yarn build
  systemctl start mafl
  msg_ok "Updated Mafl to v${RELEASE}"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:3000${CL} \n"
