#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____  _                   _          _____ __                  
   / __ \(_)___  ____ __   __(_)___     / ___// /_  ____ _________
  / /_/ / / __ \/ __ `/ | / / / __ \    \__ \/ __ \/ __ `/ ___/ _ \
 / ____/ / / / / /_/ /| |/ / / / / /   ___/ / / / / /_/ / /  /  __/
/_/   /_/_/ /_/\__, / |___/_/_/ /_/   /____/_/ /_/\__,_/_/   \___/
              /____/
EOF
}
header_info
echo -e "Loading..."
APP="Pingvin"
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
if [[ ! -d /opt/pingvin-share ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Stopping Pingvin Share"
systemctl stop pm2-root.service
msg_ok "Stopped Pingvin Share"

msg_info "Updating Pingvin Share"
cd /opt/pingvin-share
git fetch --tags
git checkout $(git describe --tags `git rev-list --tags --max-count=1`) &>/dev/null
cd backend
npm install &>/dev/null
npm run build &>/dev/null
cd ../frontend
npm install &>/dev/null
npm run build &>/dev/null
msg_ok "Updated Pingvin Share"

msg_info "Starting Pingvin Share"
systemctl start pm2-root.service
msg_ok "Started Pingvin Share"

msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:3000 ${CL} \n"
