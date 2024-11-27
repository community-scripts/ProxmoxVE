#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____             __        __  __
   / __ \____  _____/ /_____  / /_/ /_  ____ _________
  / /_/ / __ \/ ___/ //_/ _ \/ __/ __ \/ __ `/ ___/ _ \
 / ____/ /_/ / /__/ ,< /  __/ /_/ /_/ / /_/ (__  )  __/
/_/    \____/\___/_/|_|\___/\__/_.___/\__,_/____/\___/

EOF
}
header_info
echo -e "Loading..."
APP="Pocketbase"
var_disk="8"
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
  if [[ ! -f /etc/systemd/system/pocketbase.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi

  RELEASE=$(curl -s https://api.github.com/repos/pocketbase/pocketbase/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')

  if [[ ! -f /opt/${APP}_version.txt || "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop pocketbase.service
    msg_ok "Stopped ${APP}"

    msg_info "Updating $APP to v${RELEASE}"
    wget -q https://github.com/pocketbase/pocketbase/releases/download/v${RELEASE}/pocketbase_${RELEASE}_linux_amd64.zip -O /tmp/pocketbase.zip
    mkdir -p /opt/pocketbase/{pb_public,pb_migrations,pb_hooks}
    unzip -q -o /tmp/pocketbase.zip -d /opt/pocketbase
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting ${APP}"
    systemctl start pocketbase.service
    msg_ok "Started ${APP}"
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
             ${BL}http://${IP}:8080/_${CL}"
