#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
 _____
/__  /  ____  _________ __  ____  __
  / /  / __ \/ ___/ __ `/ |/_/ / / /
 / /__/ /_/ / /  / /_/ />  </ /_/ /
/____/\____/_/   \__,_/_/|_|\__, /
                           /____/
EOF
}
header_info
echo -e "Loading..."
APP="Zoraxy"
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
if [[ ! -d /opt/zoraxy/ ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/tobychui/zoraxy/releases/latest  | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Updating $APP to ${RELEASE}"
  systemctl stop zoraxy
  wget -q "https://github.com/tobychui/zoraxy/releases/download/${RELEASE}/zoraxy_linux_amd64"
  rm -rf /opt/zoraxy/zoraxy
  mv zoraxy_linux_amd64 /opt/zoraxy/zoraxy
  chmod +x /opt/zoraxy/zoraxy
  systemctl start zoraxy
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated $APP"
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
         ${BL}http://${IP}:8000${CL} \n"
