#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   ____       __        ____       _       __ 
  / __ \_____/ /_____  / __ \_____(_)___  / /_
 / / / / ___/ __/ __ \/ /_/ / ___/ / __ \/ __/
/ /_/ / /__/ /_/ /_/ / ____/ /  / / / / / /_ 
\____/\___/\__/\____/_/   /_/  /_/_/ /_/\__/

EOF
}
header_info
echo -e "Loading..."
APP="OctoPrint"
var_disk="4"
var_cpu="1"
var_ram="1024"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="0"
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
if [[ ! -d /opt/octoprint ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Stopping OctoPrint"
systemctl stop octoprint
msg_ok "Stopped OctoPrint"

msg_info "Updating OctoPrint"
source /opt/octoprint/bin/activate
pip3 install octoprint --upgrade &>/dev/null
msg_ok "Updated OctoPrint"

msg_info "Starting OctoPrint"
systemctl start octoprint
msg_ok "Started OctoPrint"
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:5000${CL} \n"
