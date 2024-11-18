#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    ______                        _     
   / ____/___  _________  ___    (_)___ 
  / /_  / __ \/ ___/ __ `/ _ \  / / __ \
 / __/ / /_/ / /  / /_/ /  __/ / / /_/ /
/_/    \____/_/   \__, /\___/_/ /\____/ 
                 /____/    /___/        
 
EOF
}
header_info
echo -e "Loading..."
APP="Forgejo"
var_disk="10"
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
if [[ ! -d /opt/forgejo ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Stopping ${APP}"
systemctl stop forgejo
msg_ok "Stopped ${APP}"

msg_info "Updating ${APP}"
RELEASE=$(curl -s https://codeberg.org/api/v1/repos/forgejo/forgejo/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+' | sed 's/^v//')
wget -qO forgejo-$RELEASE-linux-amd64 "https://codeberg.org/forgejo/forgejo/releases/download/v${RELEASE}/forgejo-${RELEASE}-linux-amd64"
rm -rf /opt/forgejo/*
cp -r forgejo-$RELEASE-linux-amd64 /opt/forgejo/forgejo-$RELEASE-linux-amd64
chmod +x /opt/forgejo/forgejo-$RELEASE-linux-amd64
ln -sf /opt/forgejo/forgejo-$RELEASE-linux-amd64 /usr/local/bin/forgejo
msg_ok "Updated ${APP}"

msg_info "Cleaning"
rm -rf forgejo-$RELEASE-linux-amd64
msg_ok "Cleaned"

msg_info "Starting ${APP}"
systemctl start forgejo
msg_ok "Started ${APP}"
msg_ok "Updated Successfully"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:3000${CL} \n"
