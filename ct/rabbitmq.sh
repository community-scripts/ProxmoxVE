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
    ____        __    __    _ __  __  _______ 
   / __ \____ _/ /_  / /_  (_) /_/  |/  / __ \
  / /_/ / __ `/ __ \/ __ \/ / __/ /|_/ / / / /
 / _, _/ /_/ / /_/ / /_/ / / /_/ /  / / /_/ / 
/_/ |_|\__,_/_.___/_.___/_/\__/_/  /_/\___\_\ 
                                              
EOF
}
header_info
echo -e "Loading..."
APP="RabbitMQ"
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
if [[ ! -d /etc/rabbitmq ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Stopping ${APP} Service"
systemctl stop rabbitmq-server
msg_ok "Stopped ${APP} Service"

msg_info "Updating..."
apt install --only-upgrade rabbitmq-server &>/dev/null
msg_ok "Update Successfully"

msg_info "Starting ${APP}"
systemctl start rabbitmq-server
msg_ok "Started ${APP}"
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}:15672${CL} \n"
