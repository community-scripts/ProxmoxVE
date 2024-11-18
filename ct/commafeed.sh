#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   ______                                ______              __
  / ____/___  ____ ___  ____ ___  ____ _/ ____/__  ___  ____/ /
 / /   / __ \/ __ `__ \/ __ `__ \/ __ `/ /_  / _ \/ _ \/ __  /
/ /___/ /_/ / / / / / / / / / / / /_/ / __/ /  __/  __/ /_/ /
\____/\____/_/ /_/ /_/_/ /_/ /_/\__,_/_/    \___/\___/\__,_/

EOF
}
header_info
echo -e "Loading..."
APP="CommaFeed"
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
if [[ ! -d /opt/commafeed ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -sL https://api.github.com/repos/Athou/commafeed/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Stopping ${APP}"
  systemctl stop commafeed
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP} to ${RELEASE}"
  wget -q https://github.com/Athou/commafeed/releases/download/${RELEASE}/commafeed-${RELEASE}-h2-jvm.zip
  unzip -q commafeed-${RELEASE}-h2-jvm.zip
  rsync -a --exclude 'data/' commafeed-${RELEASE}-h2/ /opt/commafeed/
  rm -rf commafeed-${RELEASE}-h2  commafeed-${RELEASE}-h2-jvm.zip
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP} to ${RELEASE}"

  msg_info "Starting ${APP}"
  systemctl start commafeed
  msg_ok "Started ${APP}"
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
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8082${CL} \n"
