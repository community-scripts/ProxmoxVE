#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
         _ __                __          ____     __
   _____(_) /   _____  _____/ /_  __  __/ / /__  / /_
  / ___/ / / | / / _ \/ ___/ __ \/ / / / / / _ \/ __/
 (__  ) / /| |/ /  __/ /  / /_/ / /_/ / / /  __/ /_
/____/_/_/ |___/\___/_/  /_.___/\__,_/_/_/\___/\__/

EOF
}
header_info
echo -e "Loading..."
APP="Silverbullet"
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

  service_path="/etc/systemd/system/silverbullet.service"
  if [[ ! -d /opt/silverbullet || ! -f "${service_path}" ]]; then msg_error "No ${APP} Installation Found!"; exit; fi

  RELEASE=$(curl -s https://api.github.com/repos/silverbulletmd/silverbullet/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ ! -f "/opt/silverbullet/${APP}_version.txt" || "${RELEASE}" != "$(cat /opt/silverbullet/${APP}_version.txt)" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop silverbullet.service
    msg_ok "Stopped ${APP}"

    msg_info "Updating ${APP} to ${RELEASE}"
    wget -q https://github.com/silverbulletmd/silverbullet/releases/download/${RELEASE}/silverbullet-server-linux-x86_64.zip
    unzip silverbullet-server-linux-x86_64.zip &>/dev/null
    mv silverbullet /opt/silverbullet/bin/
    chmod +x /opt/silverbullet/bin/silverbullet
    ln -sf /opt/silverbullet/bin/silverbullet /usr/local/bin/silverbullet
    echo "${RELEASE}" >/opt/silverbullet/${APP}_version.txt
    msg_ok "Updated ${APP}"

    msg_info "Starting ${APP}"
    systemctl start silverbullet.service
    sleep 1
    if systemctl status silverbullet.service &>/dev/null ; then
      msg_ok "Started ${APP}"
      msg_ok "Updated Successfully"
    else
      msg_error "Failed to start ${APP}"
    fi
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
         ${BL}http://${IP}:3000${CL} \n"
