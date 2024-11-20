#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck
# Co-Author: MountyMapleSyrup (MountyMapleSyrup)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    __                      __    _ __                    _           
   / /   ____ _____  __  __/ /   (_) /_  _________ ______(_)___ _____ 
  / /   / __ `/_  / / / / / /   / / __ \/ ___/ __ `/ ___/ / __ `/ __ \
 / /___/ /_/ / / /_/ /_/ / /___/ / /_/ / /  / /_/ / /  / / /_/ / / / /
/_____/\__,_/ /___/\__, /_____/_/_.___/_/   \__,_/_/  /_/\__,_/_/ /_/ 
                  /____/                                                                                   
EOF
}
header_info
echo -e "Loading..."
APP="LazyLibrarian"
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
if [[ ! -d /opt/LazyLibrarian/ ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Stopping LazyLibrarian"
systemctl stop lazylibrarian
msg_ok "LazyLibrarian Stopped"

msg_info "Updating $APP LXC"
git -C /opt/LazyLibrarian pull origin master &>/dev/null
msg_ok "Updated $APP LXC"

msg_info "Starting LazyLibrarian"
systemctl start lazylibrarian
msg_ok "Started LazyLibrarian"

msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:5299${CL} \n"
