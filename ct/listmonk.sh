#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: bvdberg01
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ___      __                        __  
   / (_)____/ /_____ ___  ____  ____  / /__
  / / / ___/ __/ __ `__ \/ __ \/ __ \/ //_/
 / / (__  ) /_/ / / / / / /_/ / / / / ,<   
/_/_/____/\__/_/ /_/ /_/\____/_/ /_/_/|_|  
                                           
EOF
}
header_info
echo -e "Loading..."
APP="listmonk"
var_disk="4"
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
if [[ ! -f /etc/systemd/system/listmonk.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi

RELEASE=$(curl -s https://api.github.com/repos/knadh/listmonk/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Stopping ${APP}"
  systemctl stop listmonk
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP} to v${RELEASE}"
  cd /opt
  mv /opt/listmonk/ /opt/listmonk-backup
  mkdir /opt/listmonk/
  wget -q "https://github.com/knadh/listmonk/releases/download/v${RELEASE}/listmonk_${RELEASE}_linux_amd64.tar.gz"
  tar -xzf "listmonk_${RELEASE}_linux_amd64.tar.gz" -C /opt/listmonk
  mv /opt/listmonk-backup/config.toml /opt/listmonk/config.toml
  mv /opt/listmonk-backup/uploads /opt/listmonk/uploads
  /opt/listmonk/listmonk --upgrade --yes --config /opt/listmonk/config.toml &>/dev/null
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated $APP to v${RELEASE}"

  msg_info "Starting ${APP}"
  systemctl start listmonk
  msg_ok "Started ${APP}"

  msg_info "Cleaning up"
  rm -rf "/opt/listmonk_${RELEASE}_linux_amd64.tar.gz"
  rm -rf /opt/listmonk-backup/
  msg_ok "Cleaned"

  msg_ok "Updated Successfully"
else
  msg_ok "No update required. ${APP} is already at v${RELEASE}"
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:9000${CL} \n"
