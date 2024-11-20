#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/BookStackApp/BookStack

function header_info {
clear
cat <<"EOF"
    ____              __        __             __  
   / __ )____  ____  / /_______/ /_____ ______/ /__
  / __  / __ \/ __ \/ //_/ ___/ __/ __ `/ ___/ //_/
 / /_/ / /_/ / /_/ / ,< (__  ) /_/ /_/ / /__/ ,<   
/_____/\____/\____/_/|_/____/\__/\__,_/\___/_/|_|  

EOF
}
header_info
echo -e "Loading..."
APP="Bookstack"
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
if [[ ! -d /opt/bookstack ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/BookStackApp/BookStack/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Stopping Apache2"
  systemctl stop apache2
  msg_ok "Services Stopped"

  msg_info "Updating ${APP} to ${RELEASE}"
  cp /opt/bookstack/.env /opt/.env
  wget -q "https://github.com/BookStackApp/BookStack/archive/refs/tags/v${RELEASE}.zip"
  unzip -q v${RELEASE}.zip
  mv BookStack-${RELEASE} /opt/bookstack
  mv /opt/.env /opt/bookstack/.env
  COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev  &>/dev/null
  php artisan key:generate &>/dev/null
  php artisan migrate &>/dev/null
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP}"

  msg_info "Starting Apache2"
  systemctl start apache2
  msg_ok "Started Apache2"

  msg_info "Cleaning Up"
  rm -rf v${RELEASE}.zip
  msg_ok "Cleaned"
  msg_ok "Updated Successfully"
else
  msg_ok "No update required. ${APP} is already at ${RELEASE}"
fi
exit
}
start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} Setup should be reachable by going to the following URL.
         ${BL}http://${IP}${CL} \n"
