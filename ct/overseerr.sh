#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   ____
  / __ \_   _____  _____________  ___  __________
 / / / / | / / _ \/ ___/ ___/ _ \/ _ \/ ___/ ___/
/ /_/ /| |/ /  __/ /  (__  )  __/  __/ /  / /
\____/ |___/\___/_/  /____/\___/\___/_/  /_/

EOF
}
header_info
echo -e "Loading..."
APP="Overseerr"
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
if [[ ! -d /opt/overseerr ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating $APP"
systemctl stop overseerr
cd /opt/overseerr
output=$(git pull)
git pull &>/dev/null
if echo "$output" | grep -q "Already up to date."
then
  msg_ok " $APP is already up to date."
  systemctl start overseerr
  exit
fi
yarn install &>/dev/null
yarn build &>/dev/null
systemctl start overseerr
msg_ok "Updated $APP"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:5055${CL} \n"
