#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ___              __    _            ____
   /   |  __________/ /_  (_)   _____  / __ )____  _  __
  / /| | / ___/ ___/ __ \/ / | / / _ \/ __  / __ \| |/_/
 / ___ |/ /  / /__/ / / / /| |/ /  __/ /_/ / /_/ />  <
/_/  |_/_/   \___/_/ /_/_/ |___/\___/_____/\____/_/|_|

EOF
}
header_info
echo -e "Loading..."
APP="ArchiveBox"
var_disk="8"
var_cpu="2"
var_ram="1024"
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
if [[ ! -d /opt/archivebox ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
if (( $(df /boot | awk 'NR==2{gsub("%","",$5); print $5}') > 80 )); then
  read -r -p "Warning: Storage is dangerously low, continue anyway? <y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] || exit
fi
msg_info "Stopping ${APP}"
systemctl stop archivebox
msg_ok "Stopped ${APP}"

msg_info "Updating ${APP}"
cd /opt/archivebox/data
pip install --upgrade --ignore-installed archivebox
sudo -u archivebox archivebox init
msg_ok "Updated ${APP}"

msg_info "Starting ${APP}"
systemctl start archivebox
msg_ok "Started ${APP}"

msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8000/admin/login${CL} \n"
