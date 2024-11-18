#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   ________                              ____       __            __  _           
  / ____/ /_  ____ _____  ____ ____     / __ \___  / /____  _____/ /_(_)___  ____ 
 / /   / __ \/ __ `/ __ \/ __ `/ _ \   / / / / _ \/ __/ _ \/ ___/ __/ / __ \/ __ \
/ /___/ / / / /_/ / / / / /_/ /  __/  / /_/ /  __/ /_/  __/ /__/ /_/ / /_/ / / / /
\____/_/ /_/\__,_/_/ /_/\__, /\___/  /_____/\___/\__/\___/\___/\__/_/\____/_/ /_/ 
                       /____/                                                     
EOF
}
header_info
echo -e "Loading..."
APP="Change Detection"
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
check_container_storage
check_container_resources
if [[ ! -f /etc/systemd/system/changedetection.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating ${APP} LXC"
if ! dpkg -s libjpeg-dev >/dev/null 2>&1; then
  apt-get update
  apt-get install -y libjpeg-dev
fi
pip3 install changedetection.io --upgrade &>/dev/null
pip3 install playwright --upgrade &>/dev/null
if [[ -f /etc/systemd/system/browserless.service ]]; then
  git -C /opt/browserless/ fetch --all &>/dev/null
  git -C /opt/browserless/ reset --hard origin/main &>/dev/null
  npm update --prefix /opt/browserless &>/dev/null
  npm run build --prefix /opt/browserless &>/dev/null
  npm run build:function --prefix /opt/browserless &>/dev/null
  npm prune production --prefix /opt/browserless &>/dev/null
  systemctl restart browserless
else
  msg_error "No Browserless Installation Found!"
fi
systemctl restart changedetection
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:5000${CL} \n"
