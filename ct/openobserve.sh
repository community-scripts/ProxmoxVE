#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"

   ____                   ____  __
  / __ \____  ___  ____  / __ \/ /_  ________  ______   _____
 / / / / __ \/ _ \/ __ \/ / / / __ \/ ___/ _ \/ ___/ | / / _ \
/ /_/ / /_/ /  __/ / / / /_/ / /_/ (__  )  __/ /   | |/ /  __/
\____/ .___/\___/_/ /_/\____/_.___/____/\___/_/    |___/\___/
    /_/

EOF
}
header_info
echo -e "Loading..."
APP="OpenObserve"
var_disk="3"
var_cpu="1"
var_ram="512"
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
if [[ ! -d /opt/openobserve/ ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating $APP"
systemctl stop openobserve
LATEST=$(curl -sL https://api.github.com/repos/openobserve/openobserve/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
tar zxvf <(curl -fsSL https://github.com/openobserve/openobserve/releases/download/$LATEST/openobserve-${LATEST}-linux-amd64.tar.gz) -C /opt/openobserve
systemctl start openobserve
msg_ok "Updated $APP"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:5080${CL} \n"
