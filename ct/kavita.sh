#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    __ __            _ __       
   / //_/___ __   __(_) /_____ _
  / ,< / __ `/ | / / / __/ __ `/
 / /| / /_/ /| |/ / / /_/ /_/ / 
/_/ |_\__,_/ |___/_/\__/\__,_/  
                                
EOF
}
header_info
echo -e "Loading..."
APP="Kavita"
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
if [[ ! -d /opt/Kavita ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating $APP LXC"
systemctl stop kavita
RELEASE=$(curl -s https://api.github.com/repos/Kareadita/Kavita/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
tar -xvzf <(curl -fsSL https://github.com/Kareadita/Kavita/releases/download/$RELEASE/kavita-linux-x64.tar.gz) --no-same-owner &>/dev/null
rm -rf Kavita/config
cp -r Kavita/* /opt/Kavita
rm -rf Kavita
systemctl start kavita
msg_ok "Updated $APP LXC"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:5000${CL} \n"
