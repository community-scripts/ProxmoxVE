#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____              __            _       __     __
   / __ )__  ______  / /_____  ____| |     / /__  / /_
  / __  / / / / __ \/ //_/ _ \/ ___/ | /| / / _ \/ __ \
 / /_/ / /_/ / / / / ,< /  __/ /   | |/ |/ /  __/ /_/ /
/_____/\__,_/_/ /_/_/|_|\___/_/    |__/|__/\___/_.___/

EOF
}
header_info
echo -e "Loading..."
APP="BunkerWeb"
var_disk="4"
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
if [[ ! -d /etc/bunkerweb ]]; then msg_error "No ${APP} Installation Found!"; exit; fi

RELEASE=$(curl -s https://api.github.com/repos/bunkerity/bunkerweb/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then

  msg_info "Updating ${APP} to ${RELEASE}"
  cat <<EOF >/etc/apt/preferences.d/bunkerweb
Package: bunkerweb
Pin: version ${RELEASE}
Pin-Priority: 1001
EOF
  apt-get update
  apt-get install -y nginx=1.26.2*
  apt-get install -y bunkerweb=${RELEASE}
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP} to ${RELEASE}"

else
  msg_ok "No update required. ${APP} is already at ${RELEASE}"
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} setup should be reachable by going to the following URL.
         ${BL}http://${IP}/setup${CL} \n"
