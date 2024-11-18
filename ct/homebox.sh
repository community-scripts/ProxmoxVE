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
    __  __                     ____            
   / / / /___  ____ ___  ___  / __ )____  _  __
  / /_/ / __ \/ __ `__ \/ _ \/ __  / __ \| |/_/
 / __  / /_/ / / / / / /  __/ /_/ / /_/ />  <
/_/ /_/\____/_/ /_/ /_/\___/_____/\____/_/|_|
                                                   
EOF
}
header_info
echo -e "Loading..."
APP="HomeBox"
var_disk="4"
var_cpu="1"
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
if [[ ! -f /opt/homebox ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/sysadminsmedia/homebox/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Stopping ${APP}"
  systemctl stop homebox
  msg_ok "${APP} Stopped"

  msg_info "Updating ${APP} to ${RELEASE}"
  cd /opt
  rm -rf homebox_bak
  mv homebox homebox_bak
  wget -qO- https://github.com/sysadminsmedia/homebox/releases/download/${RELEASE}/homebox_Linux_x86_64.tar.gz | tar -xzf - -C /opt
  chmod +x /opt/homebox
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated Homebox"

  msg_info "Starting ${APP}"
  systemctl start homebox
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
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:7745${CL} \n"
