#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
 _       __      __       ____  __                 __    ___    _   __
| |     / /___ _/ /______/ /\ \/ /___  __  _______/ /   /   |  / | / /
| | /| / / __ `/ __/ ___/ __ \  / __ \/ / / / ___/ /   / /| | /  |/ /
| |/ |/ / /_/ / /_/ /__/ / / / / /_/ / /_/ / /  / /___/ ___ |/ /|  /
|__/|__/\__,_/\__/\___/_/ /_/_/\____/\__,_/_/  /_____/_/  |_/_/ |_/

EOF
}
header_info
echo -e "Loading..."
APP="WatchYourLAN"
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
if [[ ! -f /lib/systemd/system/watchyourlan.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating $APP"
systemctl stop watchyourlan.service
cp -R /data/config.yaml config.yaml
RELEASE=$(curl -s https://api.github.com/repos/aceberg/WatchYourLAN/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d '"' -f 4)
wget -q https://github.com/aceberg/WatchYourLAN/releases/download/$RELEASE/watchyourlan_${RELEASE}_linux_amd64.deb
dpkg -i watchyourlan_${RELEASE}_linux_amd64.deb
cp -R config.yaml /data/config.yaml
sed -i 's|/etc/watchyourlan/config.yaml|/data/config.yaml|' /lib/systemd/system/watchyourlan.service
rm watchyourlan_${RELEASE}_linux_amd64.deb config.yaml
systemctl enable -q --now watchyourlan.service
msg_ok "Updated $APP"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8840${CL} \n"
