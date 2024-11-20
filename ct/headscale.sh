#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    __  __               __                __
   / / / /__  ____ _____/ /_____________ _/ /__
  / /_/ / _ \/ __ `/ __  / ___/ ___/ __ `/ / _ \
 / __  /  __/ /_/ / /_/ (__  ) /__/ /_/ / /  __/
/_/ /_/\___/\__,_/\__,_/____/\___/\__,_/_/\___/

EOF
}
header_info
echo -e "Loading..."
APP="Headscale"
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
if [[ ! -d /etc/headscale ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/juanfont/headscale/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
  msg_info "Stopping ${APP}"
  systemctl stop headscale
  msg_ok "Stopped ${APP}"

  msg_info "Updating $APP to v${RELEASE}"
  wget -q https://github.com/juanfont/headscale/releases/download/v${RELEASE}/headscale_${RELEASE}_linux_amd64.deb
  dpkg -i headscale_${RELEASE}_linux_amd64.deb
  rm headscale_${RELEASE}_linux_amd64.deb
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated $APP to ${RELEASE}"
  
  msg_info "Starting ${APP}"
  systemctl start headscale
  msg_ok "Started ${APP}"
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
