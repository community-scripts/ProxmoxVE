#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/burgerga/ProxmoxVE/add_outline/misc/build.func)
# Copyright (c) 2024 community-scripts ORG
# Author: Gerhard Burger (burgerga)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
   ____        __  ___
  / __ \__  __/ /_/ (_)___  ___
 / / / / / / / __/ / / __ \/ _ \
/ /_/ / /_/ / /_/ / / / / /  __/
\____/\__,_/\__/_/_/_/ /_/\___/

EOF
}
header_info
echo -e "Loading..."
APP="Outline"
var_disk="8"
var_cpu="2"
var_ram="4096"
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
if [[ ! -d /opt/outline ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/outline/outline/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
  msg_info "Stopping ${APP}"
  systemctl stop outline
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP} to ${RELEASE} (Patience)"
  cd /opt
  cp /opt/outline/.env /opt/.env
  mv /opt/outline /opt/outline_bak
  wget -q "https://github.com/outline/outline/archive/refs/tags/${RELEASE}.zip"
  unzip -q ${RELEASE}.zip
  mv outline-${RELEASE:1} /opt/outline
  cd /opt/outline

  ## Build in development mode
  unset NODE_ENV
  yarn install --no-optional --frozen-lockfile &>/dev/null &&
  yarn cache clean &>/dev/null &&
  yarn build &>/dev/null

  ## Continue in production mode
  rm -rf ./node_modules
  yarn install --production=true--frozen-lockfile &>/dev/null &&
  yarn cache clean &>/dev/null

  mv /opt/.env /opt/outline/.env

  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP} to ${RELEASE}"

  msg_info "Starting ${APP}"
  systemctl start outline
  msg_ok "Started ${APP}"
  msg_info "Cleaning up"
  rm -rf /opt/${RELEASE}.zip
  rm -rf /opt/outline_bak
  msg_ok "Cleaned"
  msg_ok "Updated Successfully"
else
  msg_ok "No update required.  ${APP} is already at ${RELEASE}."
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
