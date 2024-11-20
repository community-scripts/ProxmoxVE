#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
  ______                _____ __  
 /_  __/________ ____  / __(_) /__
  / / / ___/ __ `/ _ \/ /_/ / //_/
 / / / /  / /_/ /  __/ __/ / ,<   
/_/ /_/   \__,_/\___/_/ /_/_/|_|  

EOF
}
header_info
echo -e "Loading..."
APP="Traefik"
var_disk="2"
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
if [[ ! -f /etc/systemd/system/traefik.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/traefik/traefik/releases | grep -oP '"tag_name":\s*"v\K[\d.]+?(?=")' | sort -V | tail -n 1)
msg_info "Updating $APP LXC"
if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
  wget -q https://github.com/traefik/traefik/releases/download/v${RELEASE}/traefik_v${RELEASE}_linux_amd64.tar.gz
  tar -C /tmp -xzf traefik*.tar.gz
  mv /tmp/traefik /usr/bin/
  rm -rf traefik*.tar.gz
  systemctl restart traefik.service
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated $APP LXC"
else
  msg_ok "No update required. ${APP} is already at ${RELEASE}"
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8080${CL} \n"
