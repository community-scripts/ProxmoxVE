#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
 _____   _       ___          
/__  /  (_)___  / (_)___  ___ 
  / /  / / __ \/ / / __ \/ _ \
 / /__/ / /_/ / / / / / /  __/
/____/_/ .___/_/_/_/ /_/\___/ 
      /_/                                                  
EOF
}
header_info
echo -e "Loading..."
APP="Zipline"
var_disk="5"
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
if [[ ! -d /opt/zipline ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/diced/zipline/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Stopping ${APP}"
  systemctl stop zipline
  msg_ok "${APP} Stopped"

  msg_info "Updating ${APP} to ${RELEASE}"
  cp /opt/zipline/.env /opt/
  rm -R /opt/zipline
  wget -q "https://github.com/diced/zipline/archive/refs/tags/v${RELEASE}.zip"
  unzip -q v${RELEASE}.zip
  mv zipline-${RELEASE} /opt/zipline
  cd /opt/zipline
  mv /opt/.env /opt/zipline/.env
  yarn install &>/dev/null
  yarn build &>/dev/null
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP}"

  msg_info "Starting ${APP}"
  systemctl start zipline
  msg_ok "Started ${APP}"

  msg_info "Cleaning Up"
  rm -rf v${RELEASE}.zip
  msg_ok "Cleaned"
  msg_ok "Updated Successfully"
else
  msg_ok "No update required. ${APP} is already at ${RELEASE}"
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:3000${CL} \n"