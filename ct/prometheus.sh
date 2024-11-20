#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____                            __  __                   
   / __ \_________  ____ ___  ___  / /_/ /_  ___  __  _______
  / /_/ / ___/ __ \/ __  __ \/ _ \/ __/ __ \/ _ \/ / / / ___/
 / ____/ /  / /_/ / / / / / /  __/ /_/ / / /  __/ /_/ (__  ) 
/_/   /_/   \____/_/ /_/ /_/\___/\__/_/ /_/\___/\__,_/____/  
 
EOF
}
header_info
echo -e "Loading..."
APP="Prometheus"
var_disk="4"
var_cpu="1"
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
if [[ ! -f /etc/systemd/system/prometheus.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Stopping ${APP}"
  systemctl stop prometheus
  msg_ok "Stopped ${APP}"
  
  msg_info "Updating ${APP} to ${RELEASE}"
  wget -q https://github.com/prometheus/prometheus/releases/download/v${RELEASE}/prometheus-${RELEASE}.linux-amd64.tar.gz
  tar -xf prometheus-${RELEASE}.linux-amd64.tar.gz
  cd prometheus-${RELEASE}.linux-amd64
  cp -rf prometheus promtool /usr/local/bin/
  cd ~
  rm -rf prometheus-${RELEASE}.linux-amd64 prometheus-${RELEASE}.linux-amd64.tar.gz
  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP} to ${RELEASE}"

  msg_info "Starting ${APP}"
  systemctl start prometheus
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
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:9090${CL} \n"
