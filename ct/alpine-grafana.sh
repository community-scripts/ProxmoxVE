#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://grafana.com/

APP="Alpine-Grafana"
var_tags="${var_tags:-alpine;monitoring}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-1}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.22}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  if ! apk -e info newt >/dev/null 2>&1; then
    apk add -q newt
  fi
  LXCIP=$(ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
  while true; do
    CHOICE=$(
      whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --menu "Select option" 11 58 3 \
        "1" "Check for Grafana Updates" \
        "2" "Allow 0.0.0.0 for listening" \
        "3" "Allow only ${LXCIP} for listening" 3>&2 2>&1 1>&3
    )
    exit_status=$?
    if [ $exit_status == 1 ]; then
      clear
      exit-script
    fi
    header_info
    case $CHOICE in
    1)
      $STD apk -U upgrade
      exit
      ;;
    2)
      sed -i -e "s/cfg:server.http_addr=.*/cfg:server.http_addr=0.0.0.0/g" /etc/conf.d/grafana
      service grafana restart
      exit
      ;;
    3)
      sed -i -e "s/cfg:server.http_addr=.*/cfg:server.http_addr=$LXCIP/g" /etc/conf.d/grafana
      service grafana restart
      exit
      ;;
    esac
  done
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:3000${CL} \n"
